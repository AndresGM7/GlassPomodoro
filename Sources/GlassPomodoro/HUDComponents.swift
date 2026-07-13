import SwiftUI

// MARK: - HUD Corner Brackets (sci-fi frame alrededor del dial)

struct HUDBrackets: View {
    let tint: Color
    let pulse: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let alpha = pulse ? 0.55 + 0.25 * sin(t * 1.4) : 0.4
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let len: CGFloat = 26
                let inset: CGFloat = 2

                Path { p in
                    // top-left
                    p.move(to: CGPoint(x: inset, y: inset + len))
                    p.addLine(to: CGPoint(x: inset, y: inset))
                    p.addLine(to: CGPoint(x: inset + len, y: inset))
                    // top-right
                    p.move(to: CGPoint(x: w - inset - len, y: inset))
                    p.addLine(to: CGPoint(x: w - inset, y: inset))
                    p.addLine(to: CGPoint(x: w - inset, y: inset + len))
                    // bottom-left
                    p.move(to: CGPoint(x: inset, y: h - inset - len))
                    p.addLine(to: CGPoint(x: inset, y: h - inset))
                    p.addLine(to: CGPoint(x: inset + len, y: h - inset))
                    // bottom-right
                    p.move(to: CGPoint(x: w - inset - len, y: h - inset))
                    p.addLine(to: CGPoint(x: w - inset, y: h - inset))
                    p.addLine(to: CGPoint(x: w - inset, y: h - inset - len))
                }
                .stroke(tint.opacity(alpha), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .shadow(color: tint.opacity(alpha * 0.7), radius: 4)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Scanlines overlay (CRT sutil)

struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(0.07)))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .blendMode(.multiply)
    }
}

// MARK: - Weekly activity bars (equalizer/GitHub-style)

struct ActivityBars: View {
    let values: [Int]        // minutos por día, 7 valores, hoy al final
    let goalMinutes: Int     // meta diaria en minutos
    let tint: Color

    private let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    private func labelFor(index: Int) -> String {
        // hoy está al final; calcular el día de la semana real
        let d = Calendar.current.date(byAdding: .day, value: -(6 - index), to: Date())!
        let wd = Calendar.current.component(.weekday, from: d) // 1=Sun
        let map = [6, 0, 1, 2, 3, 4, 5] // Sun→D(6), Mon→L(0)...
        return dayLabels[map[wd - 1]]
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(0..<7, id: \.self) { i in
                let v = values[i]
                let frac = min(1.0, Double(v) / Double(max(goalMinutes, 1)))
                let isToday = i == 6
                VStack(spacing: 3) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 14, height: 34)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [tint, tint.opacity(0.5)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 14, height: max(2, 34 * frac))
                            .shadow(color: tint.opacity(frac >= 1 ? 0.8 : 0.3), radius: frac >= 1 ? 5 : 2)
                    }
                    Text(labelFor(index: i))
                        .font(.system(size: 7.5, weight: isToday ? .bold : .regular, design: .monospaced))
                        .foregroundStyle(isToday ? tint : .white.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Streak flame badge

struct StreakBadge: View {
    let streak: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 12))
                .foregroundStyle(streak > 0 ? .orange : .white.opacity(0.25))
                .shadow(color: streak > 2 ? .orange.opacity(0.7) : .clear, radius: 5)
            Text("\(streak)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(streak > 0 ? .white.opacity(0.9) : .white.opacity(0.3))
            Text("DAY STREAK")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

// MARK: - Goal ring (Apple Rings style, mini)

struct GoalRing: View {
    let done: Int
    let goal: Int
    let tint: Color

    var body: some View {
        let frac = min(1.0, Double(done) / Double(max(goal, 1)))
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: frac)
                    .stroke(
                        frac >= 1 ? Color.green : tint,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (frac >= 1 ? Color.green : tint).opacity(0.6), radius: 3)
                if frac >= 1 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(done)/\(goal)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(frac >= 1 ? .green : .white.opacity(0.9))
                Text("DAILY GOAL")
                    .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
}
