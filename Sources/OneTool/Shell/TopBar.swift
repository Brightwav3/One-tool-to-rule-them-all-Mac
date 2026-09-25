import SwiftUI

enum Page: String, CaseIterable { case convert = "Convert", creator = "Creator" }

/// `.topbar` — cog, primary nav, and the command-palette button centred in what's left.
struct TopBar: View {
    @Binding var page: Page
    var openSettings: () -> Void
    var helperDot = false

    var body: some View {
        HStack(spacing: 16) {
            CogButton(dot: helperDot, action: openSettings)
            HStack(spacing: 16) {
                ForEach(Page.allCases, id: \.self) { p in NavButton(title: p.rawValue, active: p == page) { page = p } }
            }
            SearchButton().frame(maxWidth: .infinity)
        }
        .padding(.leading, 82)   // body.is-mac .topbar — room for the traffic lights
        .padding(.trailing, 14)
        .frame(height: 44)
        .background(T.bg.gesture(WindowDragGesture()))
    }
}

struct NavButton: View {
    let title: String; let active: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(12, active ? .medium : .regular, active ? .white : T.t2)
                .padding(.horizontal, 9).frame(minHeight: 26)
                .hoverFill(active ? T.acc : .clear, active ? T.acc : T.quiet, radius: 8)
        }
        .buttonStyle(PressStyle())
    }
}

struct SearchButton: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Text("⌕").css(12, .regular, T.t3)
                Text("Search conversions, files, helpers").css(12, .regular, T.t3)
                    .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
                Kbd("⌘K")
            }
            .padding(.horizontal, 10).frame(width: 330, height: 28)
            .hoverFill(T.quiet, T.quiet2, radius: 8)
        }
        .buttonStyle(PressStyle())
    }
}

/// `.kbd`
struct Kbd: View {
    let text: String
    var fg: Color = T.t3, bg: Color = T.quiet2
    init(_ text: String, fg: Color = T.t3, bg: Color = T.quiet2) { self.text = text; self.fg = fg; self.bg = bg }
    var body: some View {
        Text(text).font(T.mono(11, .medium)).foregroundStyle(fg)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).fill(bg))
    }
}

/// The two-tone cog from index.html: a 24-point gear outline at 0.87 scale plus a
/// r3.4 hub, 1.6 stroke. It turns 45° on hover over .7s.
struct CogButton: View {
    var dot: Bool
    let action: () -> Void
    @State private var hover = false
    private static let gear: [CGPoint] = {
        let d = "10.19 1.15 13.81 1.15 14.46 3.76 16.09 4.43 18.40 3.05 20.95 5.60 19.57 7.91 20.24 9.54 22.85 10.19 22.85 13.81 20.24 14.46 19.57 16.09 20.95 18.40 18.40 20.95 16.09 19.57 14.46 20.24 13.81 22.85 10.19 22.85 9.54 20.24 7.91 19.57 5.60 20.95 3.05 18.40 4.43 16.09 3.76 14.46 1.15 13.81 1.15 10.19 3.76 9.54 4.43 7.91 3.05 5.60 5.60 3.05 7.91 4.43 9.54 3.76"
        let n = d.split(separator: " ").compactMap { Double($0) }
        return stride(from: 0, to: n.count, by: 2).map { CGPoint(x: n[$0], y: n[$0 + 1]) }
    }()
    var body: some View {
        Button(action: action) {
            Canvas { ctx, size in
                let s = size.width / 24
                var g = Path()
                for (i, p) in Self.gear.enumerated() {
                    let q = CGPoint(x: (12 + (p.x - 12) * 0.87) * s, y: (12 + (p.y - 12) * 0.87) * s)
                    i == 0 ? g.move(to: q) : g.addLine(to: q)
                }
                g.closeSubpath()
                g.addEllipse(in: CGRect(x: (12 - 3.4) * s, y: (12 - 3.4) * s, width: 6.8 * s, height: 6.8 * s))
                ctx.stroke(g, with: .color(T.cog), style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(hover ? 45 : 0))
            .animation(.timingCurve(0.33, 1, 0.68, 1, duration: 0.7), value: hover)
            .overlay(alignment: .topTrailing) {
                if dot {
                    Circle().fill(T.warn).frame(width: 7, height: 7)
                        .overlay(Circle().stroke(T.bg, lineWidth: 2)).offset(x: 2, y: -1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Settings")
    }
}
