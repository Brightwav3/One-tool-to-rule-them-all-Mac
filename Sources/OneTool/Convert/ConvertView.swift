import SwiftUI

/// renderConvert() + converter/ui/styles/convert.css (the `.u-*` rules).
struct ConvertView: View {
    var rows: [ConvertRow] = SampleData.rows
    @State private var filter: Filter = .all
    @State private var sort: Sort = .newest
    @State private var checked: Set<String> = []
    var folder = "~/Converted"

    private var visible: [ConvertRow] {
        let rank: [ConvertRow.State] = [.running, .queued, .blocked, .idle, .error, .stopped]
        let r = { (x: ConvertRow) in (rank.firstIndex(of: x.state) ?? 98) + 1 }
        return rows.enumerated().filter { filter.matches($0.element) }.sorted { a, b in
            if r(a.element) != r(b.element) { return r(a.element) < r(b.element) }
            switch sort {
            case .name: return a.element.name.localizedCompare(b.element.name) == .orderedAscending
            case .oldest: return a.offset > b.offset
            default: return a.offset < b.offset
            }
        }.map(\.element)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            list
            footer
        }
    }

    // MARK: header — destination, sort, Add files; then the filter chips
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Destination(folder: folder)
                Spacer(minLength: 0)
                Button {} label: {
                    HStack(spacing: 7) { Text(sort.rawValue).css(12, .semibold, T.t2); Chevron(size: 12, color: T.t2) }
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
            FlowLayout(spacing: 6) {
                ForEach(Filter.allCases) { f in
                    FilterChip(name: f.name, count: rows.filter(f.matches).count, on: f == filter) { filter = f }
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 12, trailing: 18))
    }

    // MARK: the table
    private var list: some View {
        GeometryReader { geo in
            let cols = Columns(width: geo.size.width)
            let shown = visible
            let lastActive = shown.lastIndex { Filter.activeStates.contains($0.state) }
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    let allOn = !shown.isEmpty && shown.allSatisfy { checked.contains($0.id) }
                    let someOn = !allOn && shown.contains { checked.contains($0.id) }
                    CheckBox(on: allOn, mixed: someOn) {
                        if allOn { checked.subtract(shown.map(\.id)) } else { checked.formUnion(shown.map(\.id)) }
                    }
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
                            UnifiedRow(row: row, cols: cols, checked: checked.contains(row.id),
                                       rule: lastActive.map { i == $0 + 1 } ?? false) {
                                if checked.contains(row.id) { checked.remove(row.id) } else { checked.insert(row.id) }
                            }
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
            }
            .background(T.surface)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(T.sep, lineWidth: 1))
        }
        .padding(.horizontal, 8).padding(.bottom, 8)
    }

    // MARK: footer — summary and the Convert button
    private var footer: some View {
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
            if !checked.isEmpty {
                GhostButton(title: "Deselect") { checked = [] }
                OutlineButton(title: "Requeue \(checked.count)") {}
                DangerButton(title: "Delete \(checked.count)") {}
            }
            ConvertButton(ready: ready, busy: busy > 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 11)
        .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
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

struct UnifiedRow: View {
    let row: ConvertRow
    let cols: Columns
    let checked: Bool
    let rule: Bool
    let toggle: () -> Void
    @State private var hover = false

    var body: some View {
        let st = row.status
        HStack(spacing: 12) {
            CheckBox(on: checked, action: toggle)
            if cols.tile { FileTile(label: row.tileLabel, thumb: row.thumb).frame(width: 26, height: 32) }
            Text(row.name).css(12.5, .semibold, row.state == .missing ? T.t3 : T.t1)
                .strikethrough(row.state == .missing, color: T.t3)
                .lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
            RoutePill(from: row.from, to: row.to, picker: row.kind == .queue, blocked: row.state == .blocked)
                .frame(width: 104, alignment: .leading)
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
        .background(checked || row.state == .running ? T.accTint : hover ? T.quiet : .clear)
        .opacity(1)
        .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }
        .overlay(alignment: .top) { if rule { Rectangle().fill(T.sep2).frame(height: 1) } }
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.25)) { hover = h } }
    }
}

/// `.u-pill` — the route, which opens the format picker on queued rows.
struct RoutePill: View {
    let from, to: String
    let picker: Bool
    let blocked: Bool
    var body: some View {
        HStack(spacing: 5) {
            Text("\(from) → \(to.isEmpty ? "Choose" : to)").lineLimit(1)
            if picker { Text("▾").font(.system(size: 7)).opacity(0.6) }
        }
        .font(T.mono(11, .semibold)).tracking(11 * 0.02)
        .foregroundStyle(blocked ? T.warnT : T.t2)
        .padding(.horizontal, 7).frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 6).fill(blocked ? T.warnTint : T.quiet2))
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

/// `.dest` — "Save to <path>" with a menu chevron, and a Change link.
struct Destination: View {
    let folder: String
    var body: some View {
        HStack(spacing: 8) {
            Button {} label: {
                HStack(spacing: 8) {
                    Text("Save to").css(12, .medium, T.t2)
                    Text(folder).font(T.mono(11)).foregroundStyle(T.t2).lineLimit(1).truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .leading)
                    Chevron()
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .hoverFill(.clear, T.quiet2, radius: 5)
            }.buttonStyle(PressStyle())
            Button {} label: {
                Text("Change").css(12, .regular, T.t1).padding(.horizontal, 6).padding(.vertical, 1)
            }.buttonStyle(PressStyle())
        }
        .padding(.leading, 2).padding(.trailing, 8).frame(minHeight: 30)
        .background(RoundedRectangle(cornerRadius: 7).fill(T.quiet))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.sep, lineWidth: 1))
        .fixedSize()
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
