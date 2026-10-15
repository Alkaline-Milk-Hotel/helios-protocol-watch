import SwiftUI

struct CyberStrideWatchView: View {
    @ObservedObject var engine: CyberStrideEngine
    @State private var lastTick: Date = .now

    var body: some View {
        ZStack {
            // 60 FPS 3D Perspective Canvas
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date
                    let dt = min(0.05, now.timeIntervalSince(lastTick))
                    DispatchQueue.main.async {
                        lastTick = now
                        engine.step(dt: dt)
                    }
                    render3DFrame(context: &context, size: size)
                }
            }
            .ignoresSafeArea()
            .focusable(true)
            .digitalCrownRotation(
                $engine.crownAccumulator,
                from: -1000.0,
                through: 1000.0,
                by: 0.05,
                sensitivity: .high,
                isContinuous: true,
                isHapticFeedbackEnabled: false
            )
            .onChange(of: engine.crownAccumulator) { newVal in
                engine.updateCrown(newValue: newVal)
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        engine.onScreenTap()
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.25)
                    .onEnded { _ in
                        if engine.overclockEnergy >= 25 {
                            engine.overclockActive = true
                        }
                    }
            )

            // HIG-Compliant Menu Overlay (All text >= 12pt, all buttons >= 48pt height)
            if engine.mode == .menu {
                VStack(spacing: 10) {
                    Text("CYBER STRIDE")
                        .font(.system(size: 19, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text("表冠转向突进 · 自动锁敌")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)

                    Button(action: { engine.startNewGame() }) {
                        Text("出击突进 START")
                            .font(.system(size: 15, weight: .black))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
                .padding(12)
                .background(Color.black.opacity(0.86))
            }
        }
    }

    private func render3DFrame(context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let cy = h * 0.47
        let focal = (w * 0.5) / tan(32.5 * .pi / 180.0)

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

        // Diegetic Reticle & 3-Cell Shield Arc
        for s in 0..<3 {
            let aStart = Angle.radians(.pi * 0.28 + Double(s) * 0.48)
            let aEnd = Angle.radians(.pi * 0.28 + Double(s) * 0.48 + 0.38)
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: 42, startAngle: aStart, endAngle: aEnd, clockwise: false)
            context.stroke(
                arc,
                with: .color(s < engine.shields ? .cyan : .gray.opacity(0.35)),
                lineWidth: 4
            )
        }

        // Project 3D Enemies
        let cosY = cos(engine.yaw)
        let sinY = sin(engine.yaw)
        for e in engine.enemies {
            let dx = e.x - engine.px
            let dz = e.z - engine.pz
            let cz = dx * cosY + dz * sinY
            let camX = -dx * sinY + dz * cosY
            guard cz > 0.35 else { continue }
            let scale = focal / cz
            let sx = cx + camX * scale
            let sy = cy
            let r = max(6.0, min(42.0, e.radius * scale))

            var poly = Path()
            poly.move(to: CGPoint(x: sx, y: sy - r))
            poly.addLine(to: CGPoint(x: sx - r * 0.85, y: sy + r * 0.7))
            poly.addLine(to: CGPoint(x: sx + r * 0.85, y: sy + r * 0.7))
            poly.closeSubpath()
            context.stroke(poly, with: .color(.pink), lineWidth: 2)
        }
    }
}
