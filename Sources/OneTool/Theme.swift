import SwiftUI
import AppKit

/// Mirrors converter/ui/styles/tokens.css. Light values come from the prototype
/// block, dark values from the last `[data-theme="dark"]` block (the one that wins).
enum T {
    static func dyn(_ light: NSColor, _ dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { app in
            app.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
    static func rgba(_ r: Int, _ g: Int, _ b: Int, _ a: Double = 1) -> NSColor {
        NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
    }
    static func hex(_ v: UInt32, _ a: Double = 1) -> NSColor {
        rgba(Int(v >> 16 & 0xff), Int(v >> 8 & 0xff), Int(v & 0xff), a)
    }
    private static func l(_ a: Double) -> NSColor { rgba(60, 60, 67, a) }
    private static func d(_ a: Double) -> NSColor { rgba(237, 237, 237, a) }

    static let bg = dyn(hex(0xf2f2f4), hex(0x000000))
    static let surface = dyn(hex(0xffffff), hex(0x000000))
    static let quiet = dyn(l(0.055), d(0.06))
    static let quiet2 = dyn(l(0.10), d(0.11))
    static let sep = dyn(l(0.13), d(0.12))
    static let sep2 = dyn(l(0.24), d(0.24))
    static let t1 = dyn(hex(0x1d1d1f), hex(0xededed))
    static let t2 = dyn(l(0.72), d(0.70))
    static let t3 = dyn(l(0.52), d(0.50))
    static let t4 = dyn(l(0.34), d(0.32))
    static let acc = dyn(hex(0x0b6bcb), hex(0x006efe))
    static let accH = dyn(hex(0x0a5fb5), hex(0x2b80ff))
    static let accText = dyn(hex(0x0b6bcb), hex(0x006efe))
    static let accTint = dyn(hex(0x0b6bcb, 0.10), hex(0x006efe, 0.18))
    static let accTint2 = dyn(hex(0x0b6bcb, 0.18), hex(0x006efe, 0.30))
    static let ok = dyn(hex(0x2f9e57), hex(0x00ad3a))
    static let okT = dyn(hex(0x1a7a41), hex(0x2bd466))
    static let okTint = dyn(hex(0x2f9e57, 0.12), hex(0x00ad3a, 0.16))
    static let warn = dyn(hex(0xe08600), hex(0xffad1f))
    static let warnT = dyn(hex(0x8a5300), hex(0xffc15c))
    static let warnTint = dyn(hex(0xe08600, 0.12), hex(0xffad1f, 0.16))
    static let scrim = Color(nsColor: rgba(20, 20, 22, 0.32))
    static let cog = dyn(hex(0x6E6E74), hex(0xEDEDED))

    /// `html{letter-spacing:-.018em}` — every text run gets size * -0.018.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if NSFont(name: "IBMPlexMono", size: size) != nil { return .custom("IBMPlexMono", size: size).weight(weight) }
        return .system(size: size, weight: weight, design: .monospaced)
    }
    static let ease = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.16)
}

extension View {
    /// Text at a CSS size with the app-wide -0.018em tracking.
    func css(_ size: CGFloat, _ weight: Font.Weight = .regular, _ color: Color = T.t1) -> some View {
        font(T.ui(size, weight)).tracking(size * -0.018).foregroundStyle(color)
    }
}

/// `.press` — a slight sink on mouse-down, no system highlight.
struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Background that swaps to `hover` while the pointer is inside — CSS :hover.
struct HoverFill<S: Shape>: ViewModifier {
    var base: Color = .clear
    var hover: Color
    var shape: S
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .background(shape.fill(on ? hover : base))
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { on = h } }
    }
}
extension View {
    func hoverFill(_ base: Color = .clear, _ hover: Color, radius: CGFloat) -> some View {
        modifier(HoverFill(base: base, hover: hover, shape: RoundedRectangle(cornerRadius: radius, style: .continuous)))
    }
}
