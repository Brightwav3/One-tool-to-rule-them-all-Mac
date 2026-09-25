import SwiftUI

let appVersion = "2.2.1"

/// Port of renderSettings() + converter/ui/styles/settings.css.
struct SettingsSheet: View {
    @Binding var isOpen: Bool
    @EnvironmentObject var store: SettingsStore
    @State private var tab = "general"
    @State private var query = ""
    @State private var openSel: String?
    @State private var openHelper: String?
    @State private var copied: String?
    @FocusState private var searchFocused: Bool

    private var q: String { query.trimmingCharacters(in: .whitespaces).lowercased() }
    private var sections: [SetSection] {
        let source = q.isEmpty ? (SettingsData.data[tab] ?? []) : SettingsData.order.flatMap { SettingsData.data[$0]! }
        return source.compactMap { sec in
            let rows = sec.rows.filter { q.isEmpty || "\($0.lab) \($0.sub)".lowercased().contains(q) }
            return rows.isEmpty ? nil : SetSection(title: sec.title, mac: sec.mac, rows: rows)
        }
    }
    /// A new category, or crossing into/out of search, is an arrival and fades in.
    private var paneKey: String { "\(tab):\(q.isEmpty ? "" : "q")" }

    var body: some View {
        // Presented as a native sheet: the system supplies the scrim, the glass edge and
        // the shadow, and the sheet sits above the window's toolbar.
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(T.sep).frame(width: 1)
            main
        }
        .frame(width: 880, height: 600)
        .background(T.bg)
        .onExitCommand { isOpen = false }
    }

    // MARK: sidebar
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("⌕").css(12, .regular, T.t3)
                TextField("", text: $query, prompt: Text("Search settings…").foregroundStyle(T.t3))
                    .textFieldStyle(.plain).font(T.ui(12)).foregroundStyle(T.t1)
                    .focused($searchFocused)
            }
            .padding(.horizontal, 10).frame(height: 32)
            .background(RoundedRectangle(cornerRadius: 8).fill(T.surface))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1))
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 10, trailing: 12))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ColLabel("One Tool").padding(EdgeInsets(top: 6, leading: 8, bottom: 4, trailing: 8))
                    ForEach(SettingsData.tabs) { t in tabButton(t) }
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 12, trailing: 8))
            }
            .scrollIndicators(.never)

            Rectangle().fill(T.sep).frame(height: 1)
            Text("One Tool \(appVersion)").font(T.mono(11)).foregroundStyle(T.t4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .frame(width: 236)
    }

    private func tabButton(_ t: SetTab) -> some View {
        let on = t.id == tab
        return Button { tab = t.id; query = ""; openSel = nil; openHelper = nil } label: {
            HStack(spacing: 10) {
                Group {
                    if t.glyph == "🗀" { Image(systemName: "folder").font(.system(size: 11)) }
                    else { Text(t.glyph).font(T.ui(12)) }
                }.opacity(0.9).frame(width: 16)
                Text(t.name).css(12.5, on ? .semibold : .medium, on ? T.t1 : T.t2)
                    .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
                if t.id == "helpers", Helpers.missing > 0 {
                    Text("\(Helpers.missing)").font(T.ui(10, .semibold)).foregroundStyle(T.warnT)
                        .padding(.horizontal, 5).frame(minWidth: 16, minHeight: 16)
                        .background(Capsule().fill(T.warnTint))
                }
            }
            .foregroundStyle(on ? T.t1 : T.t2)
            .padding(.horizontal, 9).frame(minHeight: 30)
            .hoverFill(on ? T.quiet2 : .clear, on ? T.quiet2 : T.quiet, radius: 8)
        }
        .buttonStyle(PressStyle())
    }

    // MARK: main
    private var main: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(q.isEmpty ? SettingsData.tabs.first { $0.id == tab }!.name : "Search results")
                    .css(12.5, .semibold, T.t2).frame(maxWidth: .infinity, alignment: .leading)
                CloseButton { isOpen = false }
            }
            .padding(.leading, 24).padding(.trailing, 12).frame(height: 44)

            ScrollView {
                Group {
                    if tab == "about" && q.isEmpty { AboutBox().padding(.bottom, 16) }
                    else if tab == "helpers" && q.isEmpty { helpersPane }
                    else if sections.isEmpty {
                        Text("Nothing matches “\(query)”.").css(12.5, .regular, T.t3)
                            .frame(maxWidth: .infinity).padding(40)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(sections) { sec in sectionView(sec) }
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 40)
                .id(paneKey)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
            .animation(.easeInOut(duration: 0.2), value: paneKey)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionView(_ sec: SetSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(sec.title).css(15, .semibold).tracking(15 * -0.01)
                .padding(.top, 22).padding(.bottom, 6)
            ForEach(sec.rows) { row in
                rowView(row).zIndex(openSel == row.id ? 1 : 0)
            }
        }
        .zIndex(sec.rows.contains { $0.id == openSel } ? 1 : 0)
    }

    private func rowView(_ row: SetRow) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.lab).css(12.5, .medium)
                Text(row.sub).css(11.5, .regular, T.t3).lineSpacing(11.5 * 0.2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            control(row)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
    }

    @ViewBuilder private func control(_ row: SetRow) -> some View {
        switch row.kind {
        case .toggle:
            SwitchControl(on: store.bool(row)) { store.toggle(row) }
        case .select(let opts):
            let value = store.string(row)
            Button { openSel = openSel == row.id ? nil : row.id } label: {
                HStack(spacing: 8) {
                    Text(value).css(12, .medium)
                    Text("▼").font(.system(size: 8)).foregroundStyle(T.t3)
                }
                .padding(.horizontal, 9).frame(height: 26)
                .background(RoundedRectangle(cornerRadius: 7).fill(T.surface))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.sep2, lineWidth: 1))
            }
            .buttonStyle(PressStyle())
            .overlay(alignment: .topTrailing) {
                if openSel == row.id {
                    SelectMenu(opts: opts, value: value) { store.set(row.id, $0); openSel = nil }
                        .offset(y: 30)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        case .action(let label):
            SecondaryButton(label) { if row.id == "reset" { store.reset() } }
        }
    }

    // MARK: helpers
    private var helpersPane: some View {
        let all = Helpers.all, missing = Helpers.missing
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 14) {
                    Text(missing > 0 ? "\(all.count - missing) of \(all.count) installed · \(missing) missing" : "All \(all.count) installed")
                        .css(15, .semibold).frame(maxWidth: .infinity, alignment: .leading)
                    HeadAction(title: "Get Homebrew", symbol: "arrow.up.right.square", tint: true) {
                        NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                    }
                    HeadAction(title: "Re-scan this machine", symbol: "arrow.clockwise", tint: false) { Helpers.rescan() }
                }
                Text("Free, standard tools. On Mac, set up Homebrew once, then install each missing helper here. Every conversion that needs it turns on at once; helpers stay on your machine and only run when needed.")
                    .css(11.5, .regular, T.t3).lineSpacing(11.5 * 0.25).frame(maxWidth: 560, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6).padding(.bottom, 18)
            .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }

            VStack(spacing: 0) {
                ForEach(all) { h in helperRow(h) }
            }
            .padding(.top, 4)
        }
    }

    private func helperRow(_ h: Helper) -> some View {
        let open = openHelper == h.name
        let state = h.found ? "ok" : "miss"
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(open ? "⌄" : "›").font(T.ui(11)).foregroundStyle(T.t4).frame(width: 10)
                Circle().fill(h.found ? T.ok : T.warn).frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.name).font(T.mono(12.5, .semibold)).foregroundStyle(T.t1)
                    Text("\(h.unlocks.count) conversion\(h.unlocks.count == 1 ? "" : "s")").css(11.5, .regular, T.t3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Chip(text: h.found ? "Installed" : "Missing", state: state)
            }
            .padding(EdgeInsets(top: 13, leading: 2, bottom: 13, trailing: 8))
            .hoverFill(.clear, T.quiet, radius: 8)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { openHelper = open ? nil : h.name } }

            if open {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        ColLabel(h.found ? "Runs with this helper" : "Turns on when installed")
                        FlowLayout(spacing: 6) {
                            ForEach(h.unlocks, id: \.self) { u in
                                Text(u).font(T.mono(11, .medium)).foregroundStyle(h.found ? T.t2 : T.t3)
                                    .padding(.horizontal, 8).frame(height: 22)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(T.quiet))
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        ColLabel("Install it yourself")
                        HStack(spacing: 8) {
                            Text(h.cmd).font(T.mono(11.5)).foregroundStyle(T.t2).lineLimit(1).truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(h.cmd, forType: .string)
                                copied = h.name
                            } label: {
                                Text(copied == h.name ? "Copied" : "Copy").css(12, .semibold, T.accText)
                                    .padding(.horizontal, 9).frame(minHeight: 27)
                                    .hoverFill(.clear, T.accTint, radius: 8)
                            }.buttonStyle(PressStyle())
                        }
                        .padding(EdgeInsets(top: 8, leading: 11, bottom: 8, trailing: 8))
                        .background(RoundedRectangle(cornerRadius: 8).fill(T.surface))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1))
                    }
                }
                .padding(EdgeInsets(top: 2, leading: 29, bottom: 18, trailing: 8))
                .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }
    }
}

// MARK: - small pieces

struct ColLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(T.ui(11, .semibold)).tracking(11 * 0.04).foregroundStyle(T.t3)
    }
}

/// `.sw` — 38×22 track, 18px knob, 160ms.
struct SwitchControl: View {
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Capsule().fill(on ? T.acc : T.sep2)
                .frame(width: 38, height: 22)
                .overlay(alignment: on ? .trailing : .leading) {
                    Circle().fill(.white).frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.22), radius: 1, y: 1).padding(2)
                }
                .animation(T.ease, value: on)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
    }
}

/// `.set-menu`
struct SelectMenu: View {
    let opts: [String]; let value: String; let pick: (String) -> Void
    var body: some View {
        VStack(spacing: 1) {
            ForEach(opts, id: \.self) { o in
                Button { pick(o) } label: {
                    HStack(spacing: 8) {
                        Text(o == value ? "✓" : "").font(.system(size: 10)).foregroundStyle(T.accText).frame(width: 11)
                        Text(o).css(12, o == value ? .semibold : .regular).lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8).frame(minHeight: 28)
                    .hoverFill(o == value ? T.quiet : .clear, T.quiet, radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(minWidth: 168)
        .fixedSize()
        .background(RoundedRectangle(cornerRadius: 9).fill(T.surface))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(T.sep, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.08), radius: 11, y: 8)
    }
}

/// `.set-close` — a borderless ✕.
struct CloseButton: View {
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            Text("✕").font(T.ui(11)).foregroundStyle(hover ? T.t1 : T.t3)
                .padding(.horizontal, 9).frame(minHeight: 26)
                .hoverFill(.clear, T.quiet, radius: 7)
        }
        .buttonStyle(PressStyle())
        .onHover { hover = $0 }
        .keyboardShortcut(.cancelAction)
        .focusEffectDisabled()
        .accessibilityLabel("Close settings")
    }
}

/// `.btn.btn-secondary.btn-sm`
struct SecondaryButton: View {
    let title: String; let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Button(action: action) {
            Text(title).css(12, .medium, T.accText)
                .padding(.horizontal, 10).frame(minHeight: 26)
                .hoverFill(T.surface, T.quiet, radius: 7)
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.sep2, lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }
}

/// `.set-hhead-row .set-h-action`
struct HeadAction: View {
    let title: String; let symbol: String; let tint: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                Text(title).css(12, .semibold, tint ? T.accText : T.t1)
            }
            .foregroundStyle(tint ? T.accText : T.t1)
            .padding(.horizontal, 11).frame(minHeight: 32)
            .hoverFill(tint ? T.accTint : T.quiet, tint ? T.accTint2 : T.quiet2, radius: 8)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tint ? T.accTint2 : T.sep, lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
        }
        .buttonStyle(PressStyle())
        .fixedSize()
    }
}

struct Chip: View {
    let text: String; let state: String
    var body: some View {
        Text(text).css(11, .medium, state == "ok" ? T.okT : T.warnT)
            .padding(.horizontal, 8).frame(height: 22)
            .background(Capsule().fill(state == "ok" ? T.okTint : T.warnTint))
    }
}

/// flex-wrap:wrap
struct FlowLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal.width ?? .infinity, subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (i, p) in arrange(bounds.width, subviews).points.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
    private func arrange(_ width: CGFloat, _ subviews: Subviews) -> (points: [CGPoint], size: CGSize) {
        var pts: [CGPoint] = [], x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > width { x = 0; y += row + spacing; row = 0 }
            pts.append(CGPoint(x: x, y: y)); x += sz.width + spacing; row = max(row, sz.height); maxX = max(maxX, x - spacing)
        }
        return (pts, CGSize(width: maxX, height: y + row))
    }
}
