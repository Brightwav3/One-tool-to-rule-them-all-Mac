import SwiftUI

/// settingsAboutHtml(): a System 7 “About This Macintosh” box. Fixed Platinum
/// colours in both themes, exactly like the CSS.
struct AboutBox: View {
    private let platinum = Color(white: 0xdd / 255.0)
    private func chicago(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        for n in ["Chicago", "ChicagoFLF", "Charcoal", "Geneva"] where NSFont(name: n, size: size) != nil {
            return .custom(n, size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }

    var body: some View {
        VStack(spacing: 14) {
            window
            Text("buymeacoffee.com/brightwave").font(chicago(10)).foregroundStyle(.black)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(platinum).border(.black, width: 1)
        }
        .frame(maxWidth: .infinity, minHeight: 540)
        .padding(.vertical, 24).padding(.horizontal, 8)
        .background(Checker().clipShape(RoundedRectangle(cornerRadius: 5)))
        .environment(\.colorScheme, .light)
    }

    private var window: some View {
        VStack(spacing: 0) {
            // pinstriped title bar with close box
            ZStack {
                Pinstripes().frame(height: 11).padding(.top, 4).frame(maxHeight: .infinity, alignment: .top)
                Text("About One Tool").font(chicago(12, .bold)).foregroundStyle(.black)
                    .padding(.horizontal, 8).background(platinum)
                HStack {
                    Rectangle().fill(platinum).frame(width: 11, height: 11).border(.black, width: 1)
                    Spacer()
                }.padding(.leading, 8)
            }
            .frame(height: 19)
            .overlay(alignment: .bottom) { Rectangle().fill(.black).frame(height: 1) }

            HStack(alignment: .top, spacing: 16) {
                DocMark().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 0) {
                    Text("One Tool to Rule Them All").font(chicago(14, .bold))
                    Text("Version \(appVersion)").font(chicago(12)).padding(.bottom, 8)
                    Text("Comic archives in. Real ebooks out.\nNothing leaves your machine.").font(chicago(12)).padding(.bottom, 6)
                    Text("© 2026 Brightwave. Made with care and a lot of coffee.").font(chicago(10))
                        .foregroundStyle(Color(white: 0x33 / 255.0)).padding(.bottom, 6)
                }
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 18, leading: 18, bottom: 10, trailing: 18))

            HStack(spacing: 8) {
                Text("Coffee")
                ZStack(alignment: .leading) {
                    Rectangle().fill(.white)
                    GeometryReader { g in Stripes().frame(width: g.size.width * 0.18) }
                }
                .frame(height: 10).border(.black, width: 1)
                Text("Running low")
            }
            .font(chicago(10)).foregroundStyle(.black)
            .padding(EdgeInsets(top: 0, leading: 18, bottom: 12, trailing: 18))

            HStack(spacing: 14) {
                Spacer()
                PlatinumButton(title: "Source", font: chicago(12)) {
                    NSWorkspace.shared.open(URL(string: "https://github.com/Brightwav3/One-tool-to-rule-them-all")!)
                }
                PlatinumButton(title: "☕ Buy me a coffee", font: chicago(12), isDefault: true) {
                    NSWorkspace.shared.open(URL(string: "https://buymeacoffee.com/brightwave")!)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 18, bottom: 18, trailing: 18))
        }
        .frame(maxWidth: 400)
        .background(platinum)
        .border(.black, width: 1)
        .background(Rectangle().fill(.black).offset(x: 2, y: 2))
    }
}

private struct PlatinumButton: View {
    let title: String; let font: Font; var isDefault = false; let action: () -> Void
    @State private var down = false
    var body: some View {
        Text(title).font(font).foregroundStyle(down ? .white : .black)
            .padding(.horizontal, 14).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(down ? .black : Color(white: 0xee / 255.0)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.black, lineWidth: 1))
            .padding(isDefault ? 4 : 0)
            .overlay { if isDefault { RoundedRectangle(cornerRadius: 8).strokeBorder(.black, lineWidth: 3) } }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in down = true }
                .onEnded { _ in down = false; action() })
    }
}

/// 4px two-grey checkerboard — repeating-conic-gradient(#b8b8b8 0 25%,#d4d4d4 0 50%) 0 0/4px 4px
private struct Checker: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0xd4 / 255.0)))
            var p = Path()
            for y in stride(from: 0.0, to: size.height, by: 4) {
                for x in stride(from: 0.0, to: size.width, by: 4) {
                    p.addRect(CGRect(x: x + 2, y: y, width: 2, height: 2))
                    p.addRect(CGRect(x: x, y: y + 2, width: 2, height: 2))
                }
            }
            ctx.fill(p, with: .color(Color(white: 0xb8 / 255.0)))
        }
    }
}

private struct Pinstripes: View {
    var body: some View {
        Canvas { ctx, size in
            for y in stride(from: 0.0, to: size.height, by: 2) {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black))
            }
        }
    }
}

private struct Stripes: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0x66 / 255.0)))
            for x in stride(from: 0.0, to: size.width, by: 4) {
                ctx.fill(Path(CGRect(x: x, y: 0, width: 2, height: size.height)), with: .color(.black))
            }
        }
    }
}

/// The 32×32 1-bit document mark from the SVG, scaled to 48.
private struct DocMark: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 32
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            var page = Path()
            page.move(to: pt(6, 3)); page.addLine(to: pt(20, 3)); page.addLine(to: pt(26, 9))
            page.addLine(to: pt(26, 29)); page.addLine(to: pt(6, 29)); page.closeSubpath()
            ctx.fill(page, with: .color(.white))
            let stroke = StrokeStyle(lineWidth: 2 * s)
            ctx.stroke(page, with: .color(.black), style: stroke)
            var fold = Path(); fold.move(to: pt(20, 3)); fold.addLine(to: pt(20, 9)); fold.addLine(to: pt(26, 9))
            ctx.stroke(fold, with: .color(.black), style: stroke)
            var lines = Path()
            for (y, x2) in [(15.0, 22.0), (19, 22), (23, 18)] {
                lines.move(to: pt(10, y)); lines.addLine(to: pt(x2, y))
            }
            ctx.stroke(lines, with: .color(.black), style: stroke)
        }
    }
}
