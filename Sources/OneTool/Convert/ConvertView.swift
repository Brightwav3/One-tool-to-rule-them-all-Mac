import SwiftUI

/// renderConvert() + converter/ui/styles/convert.css (the `.u-*` rules).
struct ConvertView: View {
    @StateObject private var store = ConvertStore()

    var body: some View {
        VStack(spacing: 0) {
            header.zIndex(2)
            list.zIndex(1)
            footer
        }
        .overlay(alignment: .bottomLeading) {
            if let t = store.toast {
                ToastView(toast: t)
                    .padding(.leading, 20).padding(.bottom, 74)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 16)).combined(with: .scale(scale: 0.97)),
                                            removal: .opacity.combined(with: .offset(y: 16))))
            }
        }
        .onExitCommand { store.closeMenus() }
    }

    // MARK: header — destination, sort, Add files; then the filter chips
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Destination(store: store)
                Spacer(minLength: 0)
                Button { store.closeMenus(); store.cycleSort() } label: {
                    HStack(spacing: 7) { Text(store.sort.rawValue).css(12, .semibold, T.t2); Chevron(size: 12, color: T.t2) }
                        .padding(.horizontal, 11).frame(minHeight: 28)
                        .hoverFill(.clear, T.quiet, radius: 8)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1))
                }.buttonStyle(PressStyle())
                Button {} label: {
                    HStack(spacing: 7) {
                        Text("Add files").css(12, .semibold, .white)
                        Text("⌘O").font(T.mono(9.5)).foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12).frame(minHeight: 28)
                    .hoverFill(T.acc, T.accH, radius: 8)
                }.buttonStyle(PressStyle())
            }
            .zIndex(1)
            FlowLayout(spacing: 6) {
                ForEach(Filter.allCases) { f in
                    FilterChip(name: f.name, count: store.rows.filter(f.matches).count, on: f == store.filter) {
                        store.closeMenus(); store.filter = f
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 12, trailing: 18))
    }

    // MARK: the table
    private var list: some View {
        GeometryReader { geo in
            let cols = Columns(width: geo.size.width)
            let shown = store.visible
            let lastActive = shown.lastIndex { Filter.activeStates.contains($0.state) }
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    let allOn = !shown.isEmpty && shown.allSatisfy { store.checked.contains($0.id) }
                    let someOn = !allOn && shown.contains { store.checked.contains($0.id) }
                    CheckBox(on: allOn, mixed: someOn) { store.checkAll() }
                    if cols.tile { Color.clear.frame(width: 26, height: 1) }
                    HeadCell("File").frame(maxWidth: .infinity, alignment: .leading)
                    HeadCell("Conversion").frame(width: 104, alignment: .leading)
                    if cols.status { HeadCell("Status").frame(width: 168, alignment: .leading) }
                    if cols.size { HeadCell("Size").frame(width: 64, alignment: .trailing) }
                    if cols.when { HeadCell("Written").frame(width: 92, alignment: .trailing) }
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { i, row in
                            UnifiedRow(row: row, cols: cols, store: store, rule: lastActive.map { i == $0 + 1 } ?? false)
                        }
                        if shown.isEmpty {
                            VStack(spacing: 6) {
                                Text("Nothing matches").css(13.5, .semibold)
                                Text("Nothing in this view yet.").css(12.5, .regular, T.t2)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 56).padding(.horizontal, 20)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { store.closeMenus() }
            }
            .background(T.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(T.sep, lineWidth: 1))
        }
        .padding(.horizontal, 8).padding(.bottom, 8)
        .overlayPreferenceValue(PickerAnchor.self) { anchor in
            GeometryReader { geo in
                if let anchor, let id = store.pickerFor, let row = store.rows.first(where: { $0.id == id }) {
                    let r = geo[anchor]
                    // Title, options, footer and scope card; open upwards when it won't fit below.
                    let h = CGFloat(store.candidates(for: row).count) * 34 + 170
                    let up = r.maxY + 6 + h > geo.size.height && r.minY - 6 - h > 0
                    RoutePopover(row: row, store: store)
                        .fixedSize()
                        .alignmentGuide(.leading) { $0[.trailing] - (r.minX + 104) }
                        .alignmentGuide(.top) { d in up ? -(r.minY - 6 - d.height) : -(r.maxY + 6) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        // Opaque from the first frame, so no row divider shows through it.
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.97, anchor: up ? .bottomTrailing : .topTrailing).animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.25)),
                            removal: .opacity.animation(.easeOut(duration: 0.12))))
                }
            }
        }
    }

    // MARK: footer — summary and the Convert button
    private var footer: some View {
        let rows = store.rows
        let ready = rows.filter { $0.kind == .queue && $0.state == .idle }.count
        let blocked = rows.filter { $0.state == .blocked }
        let busy = rows.filter { $0.kind == .queue && ($0.state == .queued || $0.state == .running) }.count
        let done = rows.filter { $0.kind == .queue && $0.state == .done }.count
        let written = rows.filter { $0.state == .done }.count
        let helper = blocked.first?.helper ?? "a helper"
        let summary = busy > 0
            ? "Converting \(done) of \(done + busy) · \(blocked.count) waiting on \(helper)"
            : "\(ready) ready · \(blocked.count) waiting on \(helper) · \(written) written"
        return HStack(spacing: 12) {
            Text(summary).css(12.5, .regular, T.t2).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            if !store.checked.isEmpty {
                GhostButton(title: "Deselect") { store.checked = [] }
                OutlineButton(title: "Requeue \(store.checked.count)") { store.requeue() }
                DangerButton(title: "Delete \(store.checked.count)") { store.delete() }
            }
            ConvertButton(ready: ready, busy: busy > 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 11)
        .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
    }
}

struct UnifiedRow: View {
    let row: ConvertRow
    let cols: Columns
    @ObservedObject var store: ConvertStore
    let rule: Bool
    @State private var hover = false

    var body: some View {
        let st = row.status
        let checked = store.checked.contains(row.id)
        let selected = row.kind == .queue ? store.selected.contains(row.id) : store.selectedHistory == row.id
        let open = store.pickerFor == row.id
        let dim = row.kind == .queue && !store.selected.isEmpty && !store.selected.contains(row.id) && !open
        HStack(spacing: 12) {
            CheckBox(on: checked) { store.check(row) }
            if cols.tile { FileTile(label: row.tileLabel, thumb: row.thumb).frame(width: 26, height: 32) }
            Text(row.name).css(12.5, .semibold, row.state == .missing ? T.t3 : T.t1)
                .strikethrough(row.state == .missing, color: T.t3)
                .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
            RoutePill(row: row, open: open) { store.togglePicker(row) }
                .frame(width: 104, alignment: .leading)
                .anchorPreference(key: PickerAnchor.self, value: .bounds) { open ? $0 : nil }
            if cols.status {
                HStack(spacing: 9) {
                    if st.bar {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(T.quiet2)
                                Capsule().fill(row.state == .stopped ? T.warn : T.acc).frame(width: g.size.width * row.progress)
                            }
                        }.frame(height: 4)
                    }
                    StatusLabel(text: st.label, tone: st.tone, shimmer: st.shimmer).fixedSize()
                    if !st.bar { Spacer(minLength: 0) }
                }
                .frame(width: 168, alignment: .leading)
            }
            if cols.size {
                Text(row.size.isEmpty ? "—" : row.size).font(T.mono(11.5)).foregroundStyle(T.t2)
                    .lineLimit(1).frame(width: 64, alignment: .trailing)
            }
            if cols.when {
                Text(row.when).font(T.mono(11.5)).foregroundStyle(T.t3).lineLimit(1).frame(width: 92, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(checked || selected || row.state == .running ? T.accTint : hover ? T.quiet : .clear)
        .opacity(dim ? 0.8 : 1)
        .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }
        .overlay(alignment: .top) { if rule { Rectangle().fill(T.sep2).frame(height: 1) } }
        .contentShape(Rectangle())
        .onTapGesture { store.click(row) }
        .onHover { h in withAnimation(.easeOut(duration: 0.25)) { hover = h } }
        .animation(.easeOut(duration: 0.25), value: open)
    }
}

/// The open route pill's bounds, so the picker can be drawn above every row.
struct PickerAnchor: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) { value = value ?? nextValue() }
}

/// `.u-pill` — the route; on queued rows it opens the format picker.
struct RoutePill: View {
    let row: ConvertRow
    let open: Bool
    let action: () -> Void
    var body: some View {
        let blocked = row.state == .blocked
        let label = HStack(spacing: 5) {
            Text("\(row.from) → \(row.to.isEmpty ? "Choose" : row.to)").lineLimit(1)
            if row.kind == .queue { Text(open ? "▴" : "▾").font(.system(size: 7)).opacity(0.6) }
        }
        .font(T.mono(11, .semibold)).tracking(11 * 0.02)
        .foregroundStyle(open ? .white : blocked ? T.warnT : T.t2)
        .padding(.horizontal, 7).frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 6).fill(open ? T.acc : blocked ? T.warnTint : T.quiet2))
        if row.kind == .queue { Button(action: action) { label }.buttonStyle(PressStyle()) } else { label }
    }
}

/// routePopover(): "Choose output format", the candidates, a Browse link, and the scope.
struct RoutePopover: View {
    let row: ConvertRow
    @ObservedObject var store: ConvertStore
    var body: some View {
        let options = store.candidates(for: row)
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Choose output format").css(12, .medium, T.t2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 9, trailing: 12))
                    .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }
                VStack(spacing: 0) {
                    if options.isEmpty {
                        Text("No route from \(row.from).").css(12, .regular, T.t3).padding(12)
                    }
                    ForEach(options) { t in RouteOption(tool: t, current: t.to == row.to) { store.choose(t, for: row) } }
                }
                .padding(4)
                HStack(spacing: 8) {
                    Text("Only formats \(row.from) can become.").css(11, .regular, T.t3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { store.show("Browse all isn't ported yet", ok: false) } label: {
                        Text("Browse all \(store.destinationCount)").css(12, .semibold, T.accText)
                            .padding(.horizontal, 10).frame(minHeight: 28)
                            .background(RoundedRectangle(cornerRadius: 8).fill(T.accTint))
                    }.buttonStyle(PressStyle())
                }
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 9, trailing: 9))
                .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(T.surface))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(T.sep, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .popShadow()

            HStack(spacing: 8) {
                HeadCell("Scope")
                // A real drop-down: both scopes listed, the current one ticked.
                Menu {
                    Picker("Scope", selection: $store.scopeAll) {
                        Text("This file").tag(false)
                        Text(store.allScopeLabel(row)).tag(true)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    HStack(spacing: 10) {
                        Text(store.scopeLabel(row)).css(12.5).frame(maxWidth: .infinity, alignment: .leading)
                        Chevron()
                    }
                    .padding(.horizontal, 9).frame(minHeight: 28)
                    .hoverFill(T.quiet, T.quiet2, radius: 8)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 9).fill(T.surface))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(T.sep, lineWidth: 1))
            .popShadow()
        }
        .frame(width: 262)
    }
}

struct RouteOption: View {
    let tool: Tool; let current: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Group { if current { Tick().stroke(T.accText, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)) } }
                    .frame(width: 11, height: 11).frame(width: 12)
                Text(tool.to).font(T.mono(11.5, .medium)).foregroundStyle(T.t1).frame(maxWidth: .infinity, alignment: .leading)
                Text(tool.stateLabel).css(11, .regular, tool.state == .ready ? T.okT : tool.state == .helper ? T.warnT : T.t3)
            }
            .padding(.horizontal, 8).frame(minHeight: 34)
            .hoverFill(current ? T.accTint : .clear, current ? T.accTint : T.quiet, radius: 7)
        }
        .buttonStyle(PressStyle())
        .disabled(tool.state == .soon)
        .opacity(tool.state == .soon ? 0.5 : 1)
    }
}

/// `.dest` — "Save to <path>" opening the recent-folders menu, and Change.
struct Destination: View {
    @ObservedObject var store: ConvertStore
    var body: some View {
        HStack(spacing: 8) {
            Button { store.pickerFor = nil; store.folderMenuOpen.toggle() } label: {
                HStack(spacing: 8) {
                    Text("Save to").css(12, .medium, T.t2)
                    Text(store.folder).font(T.mono(11)).foregroundStyle(T.t2).lineLimit(1).truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .leading)
                    Chevron().rotationEffect(.degrees(store.folderMenuOpen ? 180 : 0))
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.15), value: store.folderMenuOpen)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .hoverFill(.clear, T.quiet2, radius: 5)
            }.buttonStyle(PressStyle())
            Button { store.pickFolder() } label: {
                Text("Change").css(12, .regular, T.t1).padding(.horizontal, 6).padding(.vertical, 1)
            }.buttonStyle(PressStyle())
        }
        .padding(.leading, 2).padding(.trailing, 8).frame(minHeight: 30)
        .background(RoundedRectangle(cornerRadius: 7).fill(T.quiet))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.sep, lineWidth: 1))
        .fixedSize()
        // Left-aligned: the box is often narrower than the 330pt menu, and it sits
        // at the window's left edge.
        .overlay(alignment: .topLeading) {
            if store.folderMenuOpen {
                FolderMenu(store: store)
                    .offset(y: 38)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.97, anchor: .topLeading).animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.25)),
                        removal: .opacity.animation(.easeOut(duration: 0.12))))
            }
        }
    }
}

/// folderMenuHtml(): recent folders with a tick and a forget ✕, then "Choose another folder…".
struct FolderMenu: View {
    @ObservedObject var store: ConvertStore
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeadCell("Recent folders").padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
            if store.recentFolders.isEmpty {
                Text("No saved folders yet.").css(12, .regular, T.t3).padding(.horizontal, 8).padding(.vertical, 12)
            }
            ForEach(store.recentFolders, id: \.self) { f in FolderRow(path: f, current: f == store.folder, store: store) }
            Button { store.pickFolder() } label: {
                Text("Choose another folder…").css(12, .regular, T.t1).frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PressStyle())
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
            .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
            .padding(.top, 4)
        }
        .padding(4)
        .frame(width: 330)
        .background(RoundedRectangle(cornerRadius: 8).fill(T.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep, lineWidth: 1))
        .popShadow()
    }
}

struct FolderRow: View {
    let path: String; let current: Bool
    @ObservedObject var store: ConvertStore
    @State private var hover = false
    var body: some View {
        HStack(spacing: 4) {
            Button { store.setFolder(path) } label: {
                HStack(spacing: 8) {
                    Group { if current { Tick().stroke(T.accText, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)) } }
                        .frame(width: 11, height: 11).frame(width: 12)
                    Text(path).font(T.mono(11)).foregroundStyle(T.t2).lineLimit(1).truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8).contentShape(Rectangle())
            }.buttonStyle(PressStyle())
            Button { store.forget(path) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold)).foregroundStyle(T.t4)
                    .frame(width: 26, height: 26).hoverFill(.clear, T.quiet2, radius: 5)
            }
            .buttonStyle(PressStyle())
            .opacity(hover ? 1 : 0)
            .padding(.trailing, 3)
            .help("Remove \(path) from recent folders")
        }
        .frame(minHeight: 34)
        .background(RoundedRectangle(cornerRadius: 5).fill(hover ? T.quiet : .clear))
        .onHover { hover = $0 }
    }
}

/// `.toast`
struct ToastView: View {
    let toast: Toast
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(toast.ok ? T.ok : Color(nsColor: T.hex(0xe0483e)))
                .frame(width: 22, height: 22)
                .overlay {
                    if toast.ok { Tick().stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)).frame(width: 12, height: 12) }
                    else { Text("!").font(.system(size: 12, weight: .bold)).foregroundStyle(.white) }
                }
            Text(toast.title).css(12, .medium)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 11).fill(T.surface))
        .popShadow()
    }
}

extension View {
    /// --sh2: 0 1px 2px rgba(0,0,0,.05), 0 8px 22px rgba(0,0,0,.08)
    func popShadow() -> some View {
        shadow(color: .black.opacity(0.05), radius: 1, y: 1).shadow(color: .black.opacity(0.08), radius: 11, y: 8)
    }
}

/// The columns drop away as the list narrows (the @container queue rules).
struct Columns {
    let tile, status, size, when: Bool
    init(width: CGFloat) { when = width > 700; size = width > 560; status = width > 460; tile = width > 380 }
}

struct HeadCell: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(T.ui(11, .semibold)).tracking(11 * 0.04).foregroundStyle(T.t3).lineLimit(1)
    }
}

/// `.u-state`, with the moving highlight for work that can't be counted.
struct StatusLabel: View {
    let text: String; let tone: Tone; let shimmer: Bool
    private var color: Color {
        switch tone {
        case .plain: T.t2
        case .quiet: T.t3
        case .run: T.accText
        case .ok: T.okT
        case .warn: T.warnT
        case .bad: T.dangT
        }
    }
    var body: some View {
        let label = Text(text).font(T.mono(11.5, .medium)).lineLimit(1).truncationMode(.tail)
        if shimmer {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2
                label.foregroundStyle(LinearGradient(
                    stops: [.init(color: T.t3, location: 0.3), .init(color: T.t1, location: 0.5), .init(color: T.t3, location: 0.7)],
                    startPoint: UnitPoint(x: 1.5 - 2 * t, y: 0), endPoint: UnitPoint(x: 2.5 - 2 * t, y: 0)))
            }
        } else {
            label.foregroundStyle(color)
        }
    }
}

/// `.check`
struct CheckBox: View {
    let on: Bool
    var mixed = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 5)
                .fill(on ? T.acc : .clear)
                .overlay { if !on { RoundedRectangle(cornerRadius: 5).strokeBorder(T.sep2, lineWidth: 1) } }
                .overlay {
                    if on { Tick().stroke(.white, style: StrokeStyle(lineWidth: 3 * 10 / 24, lineCap: .round, lineJoin: .round)).frame(width: 10, height: 10) }
                    else if mixed { Text("–").font(.system(size: 9)).foregroundStyle(T.t1) }
                }
                .frame(width: 15, height: 15)
        }
        .buttonStyle(PressStyle())
    }
}

/// tickIcon(): M5 12.05 L9.8 16.85 L19 7.15 in a 24 box.
struct Tick: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 5 * s, y: 12.05 * s)); p.addLine(to: CGPoint(x: 9.8 * s, y: 16.85 * s)); p.addLine(to: CGPoint(x: 19 * s, y: 7.15 * s))
        return p
    }
}

/// chevron(): M4 6.5 L8 10.5 L12 6.5 in a 16 box, 1.8 stroke.
struct Chevron: View {
    var size: CGFloat = 12
    var color: Color = T.t3
    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 16
            var p = Path()
            p.move(to: CGPoint(x: 4 * s, y: 6.5 * s)); p.addLine(to: CGPoint(x: 8 * s, y: 10.5 * s)); p.addLine(to: CGPoint(x: 12 * s, y: 6.5 * s))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.8 * s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// fileThumb(): the 44×56 page with a coloured format pill, drawn at tile size.
struct FileTile: View {
    let label: String
    let thumb: ConvertRow.Thumb
    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / 44, size.height / 56)
            ctx.translateBy(x: (size.width - 44 * s) / 2, y: (size.height - 56 * s) / 2)
            ctx.scaleBy(x: s, y: s)
            let line = StrokeStyle(lineWidth: 1.2)
            if thumb == .comic {
                let back = Path(roundedRect: CGRect(x: 5, y: 5, width: 34, height: 48), cornerRadius: 3)
                ctx.fill(back, with: .color(T.bg)); ctx.stroke(back, with: .color(T.sep), style: line)
            }
            let page = Path(roundedRect: CGRect(x: 1, y: 1, width: 34, height: 48), cornerRadius: 3)
            ctx.fill(page, with: .color(T.surface)); ctx.stroke(page, with: .color(T.sep2), style: line)
            if thumb == .image {
                ctx.fill(Path(ellipseIn: CGRect(x: 9.5, y: 10.5, width: 7, height: 7)), with: .color(T.sep2))
                var m = Path()
                m.move(to: CGPoint(x: 4, y: 30)); m.addLine(to: CGPoint(x: 12, y: 21)); m.addLine(to: CGPoint(x: 19, y: 29))
                m.addLine(to: CGPoint(x: 24, y: 25)); m.addLine(to: CGPoint(x: 35, y: 35)); m.addLine(to: CGPoint(x: 35, y: 45))
                m.addLine(to: CGPoint(x: 4, y: 45)); m.closeSubpath()
                ctx.fill(m, with: .color(T.sep2.opacity(0.55)))
            } else {
                var l = Path()
                for (y, w) in [(12.0, 20.0), (18, 20), (24, 13)] { l.move(to: CGPoint(x: 8, y: y)); l.addLine(to: CGPoint(x: 8 + w, y: y)) }
                ctx.stroke(l, with: .color(T.sep2), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            if thumb == .doc {
                var c = Path()
                c.move(to: CGPoint(x: 27, y: 1)); c.addLine(to: CGPoint(x: 28, y: 1)); c.addLine(to: CGPoint(x: 35, y: 8))
                c.addLine(to: CGPoint(x: 35, y: 9)); c.addLine(to: CGPoint(x: 29, y: 9))
                c.addArc(tangent1End: CGPoint(x: 27, y: 9), tangent2End: CGPoint(x: 27, y: 7), radius: 2)
                c.closeSubpath()
                ctx.fill(c, with: .color(T.bg)); ctx.stroke(c, with: .color(T.sep2), style: line)
            }
            let tint: Color = thumb == .image ? T.ok : thumb == .comic ? T.warn : T.acc
            ctx.fill(Path(roundedRect: CGRect(x: 6, y: 33, width: 24, height: 12), cornerRadius: 2.5), with: .color(tint))
            ctx.draw(Text(label).font(T.mono(8)).foregroundStyle(.white), at: CGPoint(x: 18, y: 39.2))
        }
    }
}

/// `.u-chip`
struct FilterChip: View {
    let name: String; let count: Int; let on: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(name).css(12, on ? .semibold : .medium, on ? T.accText : T.t2)
                Text("\(count)").font(T.mono(10, .medium)).foregroundStyle(on ? T.accText : T.t2).opacity(0.65)
            }
            .padding(.horizontal, 10).frame(minHeight: 26)
            .background(Capsule().fill(on ? T.accTint : .clear))
            .overlay { if !on { Capsule().strokeBorder(T.sep2, lineWidth: 1) } }
            .contentShape(Capsule())
        }
        .buttonStyle(PressStyle())
    }
}

/// `.btn.btn-primary.go` — Convert N ⏎, disabled while nothing is ready.
struct ConvertButton: View {
    let ready: Int; let busy: Bool
    var body: some View {
        let enabled = ready > 0 && !busy
        Button {} label: {
            HStack(spacing: 8) {
                if busy {
                    ProgressView().controlSize(.mini).tint(.white)
                    Text("Converting…").css(12, .semibold, .white)
                } else {
                    Text(ready > 1 ? "Convert \(ready)" : "Convert").css(12, .semibold, enabled ? .white : T.t4)
                    Kbd("⏎", fg: .white.opacity(0.72), bg: .white.opacity(0.16))
                }
            }
            .padding(.horizontal, 12).frame(minWidth: 142, minHeight: 32)
            .hoverFill(busy ? T.acc : enabled ? T.acc : T.quiet3, enabled ? T.accH : busy ? T.acc : T.quiet3, radius: 8)
            .shadow(color: enabled ? .black.opacity(0.14) : .clear, radius: 1, y: 1)
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

struct GhostButton: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(12, .semibold, T.t2).padding(.horizontal, 10).frame(minHeight: 28)
                .hoverFill(.clear, T.quiet, radius: 8)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep, lineWidth: 1))
        }.buttonStyle(PressStyle())
    }
}
struct OutlineButton: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(12, .semibold, T.t1).padding(.horizontal, 10).frame(minHeight: 28)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1))
        }.buttonStyle(PressStyle())
    }
}
struct DangerButton: View {
    let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(12, .semibold, T.dangT).padding(.horizontal, 10).frame(minHeight: 28)
                .background(RoundedRectangle(cornerRadius: 8).fill(T.dangTint))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(red: 224/255, green: 72/255, blue: 62/255).opacity(0.28), lineWidth: 1))
        }.buttonStyle(PressStyle())
    }
}
