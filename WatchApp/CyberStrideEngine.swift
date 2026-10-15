import Foundation
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// MARK: - 3C Movement & Game State Enums
enum GameMode {
    case menu
    case armory
    case playing
    case countdown
    case result
}

enum MoveState: String {
    case cruise = "CRUISE"
    case combatBrake = "COMBAT_BRAKE"
    case killBoost = "KILL_BOOST"
    case wallGlide = "WALL_GLIDE"
    case wallStop = "WALL_STOP"
}

enum EnemyKind {
    case rusher
    case orbiter
    case aegis
    case obelisk
    case boss
}

struct WallSegment3D {
    var x1: Double
    var z1: Double
    var x2: Double
    var z2: Double
    var isCyan: Bool
    var panelIdx: Int
}

struct Pillar3D {
    var x: Double
    var z: Double
    var radius: Double
}

struct Enemy3D: Identifiable {
    let id = UUID()
    var kind: EnemyKind
    var x: Double
    var y: Double
    var z: Double
    var hp: Double
    var maxHp: Double
    var shieldHp: Double
    var plates: Int
    var speed: Double
    var radius: Double
    var rot: Double
    var facing: Double
    var shootTimer: Double
    var parryWindow: Bool = false
}

struct Projectile3D: Identifiable {
    let id = UUID()
    var x: Double
    var z: Double
    var vx: Double
    var vz: Double
    var friendly: Bool
}

// MARK: - Core 3D FPS Engine for Apple Watch
final class CyberStrideEngine: ObservableObject {
    @Published var mode: GameMode = .menu
    @Published var score: Int = 0
    @Published var bestScore: Int = 4200
    @Published var multiplier: Double = 1.0
    @Published var heatTier: Int = 1
    @Published var shields: Int = 3
    @Published var sector: Int = 1
    @Published var wave: Int = 1
    @Published var weaponIdx: Int = 0

    // Player 3C state
    @Published var px: Double = 0.0
    @Published var pz: Double = -11.5
    @Published var yaw: Double = .pi / 2.0
    @Published var crownAccumulator: Double = 0.0
    private var lastCrownValue: Double = 0.0

    @Published var moveState: MoveState = .cruise
    @Published var isWallStopped: Bool = false
    @Published var gimbalYawOffset: Double = 0.0
    @Published var lockedEnemyId: UUID? = nil

    // Skills & Timers
    @Published var overclockEnergy: Double = 70.0
    @Published var overclockActive: Bool = false
    @Published var countdownTimer: Double = 0.0

    private var baseSpeed: Double = 5.6
    private var curSpeed: Double = 5.6
    private var aimBlend: Double = 0.0
    private var killBoostTimer: Double = 0.0
    private var fireCooldown: Double = 0.0
    private var parryCooldown: Double = 0.0
    private var overclockCooldown: Double = 0.0
    private var invulnTimer: Double = 0.0
    private var combo: Int = 0

    var walls: [WallSegment3D] = []
    var pillars: [Pillar3D] = []
    var enemies: [Enemy3D] = []
    var projectiles: [Projectile3D] = []

    init() {
        rebuildArena()
    }

    // MARK: - Taptic Engine Feedback
    func triggerHaptic(_ type: String) {
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        switch type {
        case "lock":
            device.play(.click)
        case "parry":
            device.play(.success)
        case "hurt":
            device.play(.failure)
        case "kill":
            device.play(.directionUp)
        default:
            break
        }
        #endif
    }

    func startNewGame() {
        mode = .playing
        score = 0
        combo = 0
        multiplier = 1.0
        heatTier = 1
        shields = 3
        sector = 1
        wave = 1
        px = 0
        pz = -11.5
        yaw = .pi / 2.0
        curSpeed = baseSpeed
        aimBlend = 0.0
        overclockEnergy = 70.0
        overclockActive = false
        rebuildArena()
        spawnWave()
    }

    func onWristDropped() {
        if mode == .playing {
            mode = .countdown
            countdownTimer = 3.0
            overclockActive = false
        }
    }

    func updateCrown(newValue: Double) {
        let delta = newValue - lastCrownValue
        lastCrownValue = newValue
        yaw = normalizeAngle(yaw + delta * 1.45)
    }

    // MARK: - Full-Screen Tap (Shockwave Parry / 180° Quick-Turn)
    func onScreenTap() {
        if mode == .countdown {
            mode = .playing
            return
        }
        guard mode == .playing else { return }

        if isWallStopped {
            yaw = normalizeAngle(yaw + .pi)
            isWallStopped = false
            invulnTimer = 0.3
            triggerHaptic("lock")
            return
        }

        guard parryCooldown <= 0 else { return }
        parryCooldown = 1.05
        triggerHaptic("parry")

        let fwdX = cos(yaw)
        let fwdZ = sin(yaw)
        var parriedAny = false

        for i in projectiles.indices {
            if projectiles[i].friendly { continue }
            let dx = projectiles[i].x - px
            let dz = projectiles[i].z - pz
            let dist = hypot(dx, dz)
            let dot = (dx * fwdX + dz * fwdZ) / max(0.001, dist)
            if dist < 6.0 && dot > 0.45 {
                projectiles[i].friendly = true
                projectiles[i].vx = -projectiles[i].vx * 2.8
                projectiles[i].vz = -projectiles[i].vz * 2.8
                parriedAny = true
            }
        }

        for i in enemies.indices {
            let dx = enemies[i].x - px
            let dz = enemies[i].z - pz
            let dist = hypot(dx, dz)
            let dot = (dx * fwdX + dz * fwdZ) / max(0.001, dist)
            if dist < 5.5 && dot > 0.45 {
                enemies[i].shieldHp = 0
                enemies[i].hp -= enemies[i].parryWindow ? 999 : 30
                parriedAny = true
            }
        }

        if parriedAny {
            shields = min(3, shields + 1)
        }
    }

    // MARK: - Step Simulation (60 FPS)
    func step(dt: Double) {
        if mode == .countdown {
            countdownTimer -= dt
            if countdownTimer <= 0 {
                mode = .playing
            }
            return
        }
        guard mode == .playing else { return }

        if invulnTimer > 0 { invulnTimer = max(0, invulnTimer - dt) }
        if parryCooldown > 0 { parryCooldown = max(0, parryCooldown - dt) }
        if overclockCooldown > 0 { overclockCooldown = max(0, overclockCooldown - dt) }

        if overclockActive {
            overclockEnergy -= 35.0 * dt
            if overclockEnergy <= 0 {
                overclockEnergy = 0
                overclockActive = false
                overclockCooldown = 1.0
            }
        }

        stepMovement(dt: dt)
        stepGimbalAndCombat(dt: dt)
        stepEnemies(dt: dt)
    }

    private func stepMovement(dt: Double) {
        if lockedEnemyId != nil {
            aimBlend = min(1.0, aimBlend + dt * 2.8)
        } else {
            aimBlend = max(0.0, aimBlend - dt * 3.4)
        }
        let aimWeight = aimBlend * aimBlend * (3.0 - 2.0 * aimBlend)

        var targetSpeed = baseSpeed
        moveState = .cruise

        if killBoostTimer > 0 {
            killBoostTimer -= dt
            targetSpeed = baseSpeed * 1.45
            moveState = .killBoost
        } else if aimWeight > 0.01 {
            let locked = enemies.first(where: { $0.id == lockedEnemyId })
            let d = locked != nil ? hypot(locked!.x - px, locked!.z - pz) : 9.0
            let t = max(0.0, min(1.0, (d - 3.5) / 9.0))
            let distSmooth = t * t * (3.0 - 2.0 * t)
            let engagedRatio = 0.22 + 0.72 * distSmooth
            let blendedRatio = 1.0 - aimWeight * (1.0 - engagedRatio)
            targetSpeed = baseSpeed * blendedRatio
            if locked != nil {
                moveState = .combatBrake
            }
        }

        // Soft physical momentum damping: gentle deceleration (3.6) and smooth acceleration (5.2)
        let accelRate = targetSpeed < curSpeed ? 3.6 : 5.2
        curSpeed += (targetSpeed - curSpeed) * min(1.0, dt * accelRate)
        let fwdX = cos(yaw)
        let fwdZ = sin(yaw)
        var nextX = px + fwdX * curSpeed * dt
        var nextZ = pz + fwdZ * curSpeed * dt
        isWallStopped = false

        let rBound = 16.8
        let distCenter = hypot(nextX, nextZ)
        if distCenter > rBound {
            let nx = -nextX / distCenter
            let nz = -nextZ / distCenter
            nextX = -nx * rBound
            nextZ = -nz * rBound

            let intoWall = -(fwdX * nx + fwdZ * nz)
            let incidenceDeg = acos(max(-1.0, min(1.0, intoWall))) * 180.0 / .pi
            if 90.0 - incidenceDeg >= 70.0 {
                isWallStopped = true
                curSpeed = 0
                moveState = .wallStop
            } else {
                moveState = .wallGlide
            }
        }

        px = nextX
        pz = nextZ
    }

    private func stepGimbalAndCombat(dt: Double) {
        let maxRad = 15.0 * .pi / 180.0
        var bestIdx: Int? = nil
        var bestDelta: Double = 999.0

        for i in enemies.indices where enemies[i].hp > 0 {
            let dx = enemies[i].x - px
            let dz = enemies[i].z - pz
            let dist = hypot(dx, dz)
            if dist > 24.0 { continue }
            let delta = normalizeAngle(atan2(dz, dx) - yaw)
            if abs(delta) <= maxRad && abs(delta) < abs(bestDelta) {
                bestDelta = delta
                bestIdx = i
            }
        }

        if let idx = bestIdx {
            if lockedEnemyId != enemies[idx].id {
                triggerHaptic("lock")
            }
            lockedEnemyId = enemies[idx].id
            gimbalYawOffset += (bestDelta - gimbalYawOffset) * min(1.0, dt * 18.0)

            if fireCooldown > 0 { fireCooldown -= dt }
            if fireCooldown <= 0 && !isWallStopped {
                fireCooldown = 0.12
                enemies[idx].hp -= 12.0
                if enemies[idx].hp <= 0 {
                    onEnemyKilled(enemies[idx])
                }
            }
        } else {
            lockedEnemyId = nil
            gimbalYawOffset *= max(0.0, 1.0 - dt * 12.0)
        }
    }

    private func resolveEnemyWallAndPillarPenetration(_ enemy: inout Enemy3D) {
        let maxR = 16.2 - enemy.radius
        let distCenter = hypot(enemy.x, enemy.z)
        if distCenter > maxR && distCenter > 0.001 {
            enemy.x = (enemy.x / distCenter) * maxR
            enemy.z = (enemy.z / distCenter) * maxR
        }
        for p in pillars {
            let dx = enemy.x - p.x
            let dz = enemy.z - p.z
            let d = hypot(dx, dz)
            let minD = p.radius + enemy.radius
            if d < minD && d > 0.001 {
                enemy.x = p.x + (dx / d) * minD
                enemy.z = p.z + (dz / d) * minD
            }
        }
    }

    private func stepEnemies(dt: Double) {
        let scale = overclockActive ? 0.22 : 1.0
        let edt = dt * scale

        for i in enemies.indices where enemies[i].hp > 0 {
            enemies[i].rot += edt * 2.5
            let dx = px - enemies[i].x
            let dz = pz - enemies[i].z
            let dist = max(0.001, hypot(dx, dz))
            enemies[i].x += (dx / dist) * enemies[i].speed * edt
            enemies[i].z += (dz / dist) * enemies[i].speed * edt
            resolveEnemyWallAndPillarPenetration(&enemies[i])
            enemies[i].parryWindow = dist < 4.2

            if dist < 1.3 && invulnTimer <= 0 {
                shields = max(0, shields - 1)
                invulnTimer = 1.1
                combo = 0
                multiplier = 1.0
                heatTier = max(1, heatTier - 1)
                triggerHaptic("hurt")
                if shields <= 0 {
                    mode = .result
                }
            }
        }

        enemies.removeAll { $0.hp <= 0 }
        if enemies.isEmpty && mode == .playing {
            wave += 1
            if wave > 2 {
                sector += 1
                wave = 1
                shields = min(3, shields + 1)
                rebuildArena()
            }
            spawnWave()
        }
    }

    private func onEnemyKilled(_ e: Enemy3D) {
        triggerHaptic("kill")
        combo += 1
        multiplier = combo >= 12 ? 3.0 : combo >= 5 ? 2.0 : combo >= 2 ? 1.5 : 1.0
        heatTier = combo >= 12 ? 3 : combo >= 5 ? 2 : 1
        score += Int(100.0 * multiplier)
        bestScore = max(bestScore, score)
        killBoostTimer = 0.45

        // Strict safeguard: zero energy gain while Chronos Overclock is active
        if !overclockActive && overclockCooldown <= 0 {
            overclockEnergy = min(100.0, overclockEnergy + 14.0)
        }
    }

    private func rebuildArena() {
        walls.removeAll()
        let r = 18.5
        for i in 0..<8 {
            let a1 = Double(i) * .pi / 4.0 + .pi / 8.0
            let a2 = Double((i + 1) % 8) * .pi / 4.0 + .pi / 8.0
            let x1 = cos(a1) * r, z1 = sin(a1) * r
            let x2 = cos(a2) * r, z2 = sin(a2) * r
            for s in 0..<4 {
                let t1 = Double(s) / 4.0
                let t2 = Double(s + 1) / 4.0
                walls.append(WallSegment3D(
                    x1: x1 + (x2 - x1) * t1,
                    z1: z1 + (z2 - z1) * t1,
                    x2: x1 + (x2 - x1) * t2,
                    z2: z1 + (z2 - z1) * t2,
                    isCyan: (i + s) % 2 == 0,
                    panelIdx: s
                ))
            }
        }
        pillars = [Pillar3D(x: 0, z: 0, radius: 2.2)]
    }

    private func spawnWave() {
        enemies.removeAll()
        let count = 4 + min(3, sector)
        for i in 0..<count {
            let ang = Double(i) * (.pi * 2.0 / Double(count))
            enemies.append(Enemy3D(
                kind: i % 2 == 0 ? .rusher : .orbiter,
                x: cos(ang) * 10.5,
                y: 0,
                z: sin(ang) * 10.5,
                hp: 36,
                maxHp: 36,
                shieldHp: 0,
                plates: 0,
                speed: 3.6,
                radius: 0.9,
                rot: 0,
                facing: 0,
                shootTimer: 2.0
            ))
        }
    }

    func normalizeAngle(_ a: Double) -> Double {
        var res = a
        while res > .pi { res -= .pi * 2.0 }
        while res < -.pi { res += .pi * 2.0 }
        return res
    }
}
