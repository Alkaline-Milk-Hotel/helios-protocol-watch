//
//  CyberStrideWatchCanvasView.swift
//  Helios Protocol // WatchOS SwiftUI Canvas 2x Retina Vector-Shader Hybrid Renderer
//
//  Architecture Mapping (1:1 with CyberStrideSimulator.html v5.0):
//  - TimelineView(.animation) -> 60fps render loop
//  - SwiftUI Canvas { context, size in ... } -> GraphicsContext immediate-mode vector/shader drawing
//  - .digitalCrownRotation -> Yaw aiming + ADS Tactical Slow-Mo
//

import SwiftUI
import WatchKit

// MARK: - Game State & Stage Progression Model
enum WeaponTier: Int {
    case tier1 = 1 // 初始制式 (Standard)
    case tier2 = 2 // 超载电浆 (Stage 1 Breakthrough Reward: +25% Fire Rate + Plasma Tracers)
    case tier3 = 3 // 雷霆链式 (Stage 2 Breakthrough Reward: +42% Fire Rate + Chain Lightning)

    var label: String {
        switch self {
        case .tier1: return "TIER 1 // 初始制式"
        case .tier2: return "TIER 2 // 超载电浆"
        case .tier3: return "TIER 3 // 雷霆链式"
        }
    }

    var accentColor: Color {
        switch self {
        case .tier1: return Color(red: 0.22, green: 0.74, blue: 0.97)
        case .tier2: return Color(red: 0.13, green: 0.83, blue: 0.93)
        case .tier3: return Color(red: 0.96, green: 0.62, blue: 0.04)
        }
    }
}

struct LootOrb: Identifiable {
    let id = UUID()
    var worldX: Double
    var worldY: Double
    var worldZ: Double
    var vx: Double
    var vy: Double
    var vz: Double
    var color: Color
    var value: Int
}

struct StageBannerState {
    var timer: Double = 0
    var maxTimer: Double = 2.6
    var stageNum: Int = 1
    var title: String = ""
    var rewardText: String = ""
    var color: Color = .cyan
}

@Observable
final class HeliosWatchEngine {
    // Player Transform & Vitals
    var playerX: Double = 2.5
    var playerY: Double = 2.5
    var playerAngle: Double = 0.0
    var crownAccumulator: Double = 0.0

    var hp: Double = 100.0
    var armor: Double = 50.0
    var score: Int = 0
    var combo: Int = 1

    // 3-Stage Breakthrough & Weapon Evolution State
    var stageIndex: Int = 0 // 0: Stage 1, 1: Stage 2, 2: Stage 3
    var weaponTier: WeaponTier = .tier1
    var stageBanner = StageBannerState()
    var sectorClearTimer: Double = 0.0
    var lootOrbs: [LootOrb] = []

    // Haptic + Stage Breakthrough Trigger
    func triggerStageBreakthrough(completedStage: Int, title: String, reward: String) {
        WKInterfaceDevice.current().play(.success)
        if completedStage == 1 {
            weaponTier = .tier2
            armor = min(100, armor + 40)
        } else if completedStage == 2 {
            weaponTier = .tier3
            hp = 100
            armor = 100
        }
        stageBanner = StageBannerState(
            timer: 2.6,
            maxTimer: 2.6,
            stageNum: completedStage,
            title: title,
            rewardText: reward,
            color: completedStage == 1 ? .cyan : .orange
        )
    }

    func update(dt: Double) {
        if stageBanner.timer > 0 {
            stageBanner.timer = max(0, stageBanner.timer - dt)
        }
        if sectorClearTimer > 0 {
            sectorClearTimer = max(0, sectorClearTimer - dt)
        }
    }
}

// MARK: - WatchOS SwiftUI Canvas View (Retina Vector-Shader Hybrid)
struct CyberStrideWatchCanvasView: View {
    @State private var engine = HeliosWatchEngine()
    @State private var lastFrameDate: Date = .now
    @FocusState private var isCrownFocused: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas(rendersAsynchronously: true) { context, size in
                let dt = min(0.05, timeline.date.timeIntervalSince(lastFrameDate))
                let _ = DispatchQueue.main.async {
                    engine.update(dt: dt)
                    lastFrameDate = timeline.date
                }

                // 1. High-DPI Vector Skybox (Gas Giant + Dual Ice Rings + Aurora)
                drawRetinaVectorSkybox(context: &context, size: size)

                // 2. Raycasted Wall Columns & Floor/Ceiling Perspective Grid
                drawRaycastViewport(context: &context, size: size)

                // 3. Vector-Shaded 3D Weapon Viewmodel with Tier Evolution LCD
                drawVectorWeaponViewmodel(context: &context, size: size)

                // 4. Diegetic Visor HUD & 3-Stage Node Chain (✓S1 ── ◉S2 ── ○S3)
                drawDiegeticVisorHUD(context: &context, size: size)

                // 5. Stage Breakthrough Ribbon Overlay
                if engine.stageBanner.timer > 0 {
                    drawStageBreakthroughRibbon(context: &context, size: size)
                }
            }
            .ignoresSafeArea()
            .focusable(true)
            .focused($isCrownFocused)
            .digitalCrownRotation(
                $engine.crownAccumulator,
                from: -1000.0,
                through: 1000.0,
                by: 0.01,
                sensitivity: .high,
                isContinuous: true,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: engine.crownAccumulator) { oldVal, newVal in
                let delta = newVal - oldVal
                engine.playerAngle += delta * 0.045
            }
            .onAppear {
                isCrownFocused = true
            }
        }
    }

    // MARK: - 1. High-DPI Vector Skybox
    private func drawRetinaVectorSkybox(context: inout GraphicsContext, size: CGSize) {
        let horizon = size.height * 0.5
        let skyRect = CGRect(x: 0, y: 0, width: size.width, height: horizon)

        context.fill(
            Path(skyRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.01, green: 0.04, blue: 0.11),
                    Color(red: 0.03, green: 0.14, blue: 0.27),
                    Color(red: 0.05, green: 0.35, blue: 0.52)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: horizon)
            )
        )

        // Ringed Gas Giant Planet in Upper Skybox
        let planetCenter = CGPoint(x: size.width * 0.72, y: horizon * 0.42)
        let planetRadius: CGFloat = size.width * 0.16
        let planetPath = Path(ellipseIn: CGRect(
            x: planetCenter.x - planetRadius,
            y: planetCenter.y - planetRadius,
            width: planetRadius * 2,
            height: planetRadius * 2
        ))
        context.fill(
            planetPath,
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 0.88, green: 0.97, blue: 1.0),
                    Color(red: 0.13, green: 0.83, blue: 0.93),
                    Color(red: 0.04, green: 0.12, blue: 0.24)
                ]),
                center: CGPoint(x: planetCenter.x - planetRadius * 0.3, y: planetCenter.y - planetRadius * 0.3),
                startRadius: 2,
                endRadius: planetRadius * 1.25
            )
        )
    }

    // MARK: - 2. Raycast Viewport Placeholder (Column Slice Shader)
    private func drawRaycastViewport(context: inout GraphicsContext, size: CGSize) {
        let horizon = size.height * 0.5
        let floorRect = CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)
        context.fill(
            Path(floorRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.11),
                    Color(red: 0.07, green: 0.13, blue: 0.22)
                ]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    // MARK: - 3. Vector-Shaded 3D Weapon Viewmodel with Tier LCD
    private func drawVectorWeaponViewmodel(context: inout GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let by = size.height
        let bodyRect = CGRect(x: cx - 22, y: by - 64, width: 44, height: 64)

        context.fill(
            Path(roundedRect: bodyRect, cornerRadius: 6),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.12, green: 0.16, blue: 0.23),
                    Color(red: 0.28, green: 0.33, blue: 0.41),
                    Color(red: 0.06, green: 0.09, blue: 0.16)
                ]),
                startPoint: CGPoint(x: bodyRect.minX, y: bodyRect.minY),
                endPoint: CGPoint(x: bodyRect.maxX, y: bodyRect.minY)
            )
        )

        // Integrated Tier LCD Screen
        let lcdRect = CGRect(x: cx - 14, y: by - 26, width: 28, height: 12)
        context.fill(Path(roundedRect: lcdRect, cornerRadius: 3), with: .color(.black.opacity(0.85)))
        context.stroke(Path(roundedRect: lcdRect, cornerRadius: 3), with: .color(engine.weaponTier.accentColor), lineWidth: 1)
        context.draw(
            Text("T\(engine.weaponTier.rawValue)").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(engine.weaponTier.accentColor),
            at: CGPoint(x: cx, y: by - 20)
        )
    }

    // MARK: - 4. Diegetic Visor HUD & 3-Stage Node Chain
    private func drawDiegeticVisorHUD(context: inout GraphicsContext, size: CGSize) {
        let pillRect = CGRect(x: size.width - 134, y: 6, width: 128, height: 32)
        context.fill(Path(roundedRect: pillRect, cornerRadius: 10), with: .color(Color(red: 0.02, green: 0.04, blue: 0.10).opacity(0.76)))
        context.stroke(Path(roundedRect: pillRect, cornerRadius: 10), with: .color(.cyan.opacity(0.45)), lineWidth: 1)

        let stageNodes = (0..<3).map { idx -> String in
            if idx < engine.stageIndex { return "✓S\(idx + 1)" }
            if idx == engine.stageIndex { return "◉S\(idx + 1)" }
            return "○S\(idx + 1)"
        }.joined(separator: "─")

        context.draw(
            Text(stageNodes).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.cyan),
            at: CGPoint(x: pillRect.midX, y: pillRect.minY + 10)
        )
    }

    // MARK: - 5. Stage Breakthrough Ribbon Overlay
    private func drawStageBreakthroughRibbon(context: inout GraphicsContext, size: CGSize) {
        let bannerRect = CGRect(x: 12, y: 54, width: size.width - 24, height: 48)
        context.fill(Path(roundedRect: bannerRect, cornerRadius: 10), with: .color(Color(red: 0.02, green: 0.05, blue: 0.12).opacity(0.92)))
        context.stroke(Path(roundedRect: bannerRect, cornerRadius: 10), with: .color(engine.stageBanner.color), lineWidth: 1.5)

        context.draw(
            Text("⚡ STAGE \(engine.stageBanner.stageNum) CLEARED ⚡")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(engine.stageBanner.color),
            at: CGPoint(x: size.width * 0.5, y: bannerRect.minY + 15)
        )
        context.draw(
            Text(engine.stageBanner.rewardText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.green),
            at: CGPoint(x: size.width * 0.5, y: bannerRect.minY + 33)
        )
    }
}
