import SwiftUI

/// renderPanel() + styles/inspector.css: the 308pt panel beside the list. It edits
/// the selected queued file, describes a selected written file, or summarises the batch.
struct InspectorView: View {
    @ObservedObject var store: ConvertStore

    var body: some View {
        Group {
            if let r = store.historyRow { HistoryPanel(row: r, store: store) }
            else if let f = store.focusedRow { FilePanel(row: f, store: store) }
            else { BatchPanel(store: store) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(T.bg)
    }
}

// MARK: - pieces shared by the three panels

/// `.section` / `.i-sec`: a bold line and a secondary one, ruled underneath.
struct PanelSection<Sub: View>: View {
    let title: String
    @ViewBuilder var sub: Sub
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).css(13, .semibold)
            sub
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18).padding(.vertical, 16)
        .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }
    }
}

/// `.kv`: label left, mono value right.
struct KV: View {
    let k: String; let v: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(k).css(12, .regular, T.t2).frame(maxWidth: .infinity, alignment: .leading)
            Text(v).font(T.mono(11, .medium)).foregroundStyle(T.t2).lineLimit(1).truncationMode(.middle)
                .frame(maxWidth: 190, alignment: .trailing).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// `.divider`: a top rule with 13pt above the content.
struct Divided<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 13)
            .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
    }
}

/// `.i-route`: the accent chip.
struct RouteChip: View {
    let text: String
    var body: some View {
        Text(text).font(T.mono(11, .medium)).foregroundStyle(T.accText)
            .padding(.horizontal, 8).frame(height: 22)
            .background(Capsule().fill(T.accTint))
    }
}

/// The rename field: an editable stem, the fixed extension, and a hint.
struct RenameField: View {
    let label: String
    let stem: String
    let ext: String
    let hint: String
    var locked = false
    let commit: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).css(12, .medium, T.t2)
            HStack(spacing: 8) {
                TextField("", text: $text)
                    .textFieldStyle(.plain).font(T.ui(12)).foregroundStyle(T.t1)
                    .padding(.horizontal, 10).frame(height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(T.surface))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(focused ? T.acc : T.sep2, lineWidth: 1))
                    .background(RoundedRectangle(cornerRadius: 8).stroke(focused ? T.accTint : .clear, lineWidth: 6))
                    .focused($focused)
                    .disabled(locked).opacity(locked ? 0.6 : 1)
                    .onSubmit { if text != stem && !text.isEmpty { commit(text) } }
                    .onExitCommand { text = stem; focused = false }
                Text(ext).font(T.mono(11)).foregroundStyle(T.t3)
            }
            Text(hint).css(11, .regular, T.t3).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { text = stem }
        .onChange(of: stem) { _, new in text = new }
    }
}

/// folderIcon(): the 48pt blue folder whose flap dips and sheet rises on hover.
struct FolderButton: View {
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                FolderBack().fill(Color(nsColor: T.hex(0x2563EB)))
                RoundedRectangle(cornerRadius: 1.5).fill(Color(nsColor: T.hex(0xEFF6FF)))
                    .frame(width: 32, height: 9).offset(x: 8, y: hover ? 14 : 25)
                RoundedRectangle(cornerRadius: 4).fill(Color(nsColor: T.hex(0x3B82F6)))
                    .frame(width: 40, height: 26)
                    .scaleEffect(x: 1, y: hover ? 0.72 : 1, anchor: .bottom)
                    .rotationEffect(.degrees(hover ? 4 : 0), anchor: .bottom)
                    .offset(x: 4, y: 13)
            }
            .frame(width: 48, height: 48)
            .animation(.timingCurve(0.34, 1.32, 0.52, 1, duration: 0.36), value: hover)
        }
        .buttonStyle(PressStyle())
        .onHover { hover = $0 }
        .help("Open location")
    }
}
private struct FolderBack: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 4, y: 13))
        p.addArc(tangent1End: CGPoint(x: 4, y: 9), tangent2End: CGPoint(x: 8, y: 9), radius: 4)
        p.addLine(to: CGPoint(x: 17.2, y: 9)); p.addLine(to: CGPoint(x: 20, y: 10.2)); p.addLine(to: CGPoint(x: 23, y: 13))
        p.addLine(to: CGPoint(x: 40, y: 13))
        p.addArc(tangent1End: CGPoint(x: 44, y: 13), tangent2End: CGPoint(x: 44, y: 17), radius: 4)
        p.addLine(to: CGPoint(x: 44, y: 35))
        p.addArc(tangent1End: CGPoint(x: 44, y: 39), tangent2End: CGPoint(x: 40, y: 39), radius: 4)
        p.addLine(to: CGPoint(x: 8, y: 39))
        p.addArc(tangent1End: CGPoint(x: 4, y: 39), tangent2End: CGPoint(x: 4, y: 35), radius: 4)
        p.closeSubpath()
        return p
    }
}

private struct PanelButton: View {
    let title: String; var primary = false; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(12, .semibold, primary ? .white : T.t1)
                .frame(maxWidth: .infinity, minHeight: 32)
                .hoverFill(primary ? T.acc : .clear, primary ? T.accH : T.quiet, radius: 8)
                .overlay { if !primary { RoundedRectangle(cornerRadius: 8).strokeBorder(T.sep2, lineWidth: 1) } }
        }.buttonStyle(PressStyle())
    }
}

// MARK: - a queued file

struct FilePanel: View {
    let row: ConvertRow
    @ObservedObject var store: ConvertStore

    var body: some View {
        let queue = store.queue
        let index = (queue.firstIndex { $0.id == row.id } ?? 0) + 1
        let tool = store.tools.first { $0.id == row.conv } ?? store.tools.first { $0.from == row.from && $0.to == row.to }
        let out = ((row.outputPath ?? row.name) as NSString)
        let locked = row.state == .queued || row.state == .running
        VStack(spacing: 0) {
            PanelSection(title: "Editing \(index) of \(queue.count) files") {
                Text("Changes apply to this file unless you say otherwise.").css(12, .regular, T.t2)
            }
            HStack(alignment: .top, spacing: 12) {
                FileTile(label: row.tileLabel, thumb: row.thumb).frame(width: 44, height: 56)
                VStack(alignment: .leading, spacing: 0) {
                    Text(row.name).css(13, .semibold).lineLimit(1).truncationMode(.tail)
                    Text(row.metaLine).font(T.mono(11)).foregroundStyle(T.t2).padding(.top, 8)
                    RouteChip(text: "\(row.from) → \(row.to.isEmpty ? "Choose" : row.to)").padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                FolderButton { store.reveal(row.sourcePath) }.padding(.top, -3)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    Divided {
                        VStack(alignment: .leading, spacing: 8) {
                            KV(k: "Source", v: [row.from.uppercased(), fmtSize(row.sourceBytes)].filter { !$0.isEmpty }.joined(separator: " · "))
                            KV(k: "Type", v: tool?.cat ?? "File")
                        }
                    }
                    Divided {
                        HStack {
                            Text(row.thumb == .comic ? "Archive" : row.thumb == .image ? "Image facts" : "File facts").css(12, .medium, T.t2)
                            Spacer()
                            Text("● Readable").css(12, .medium, T.okT)
                        }
                        Text(row.thumb == .comic ? "Package detected" : row.thumb == .image ? "Source image · Original dimensions" : "Ready to inspect")
                            .font(T.mono(11)).foregroundStyle(T.t3).padding(.top, 9)
                    }
                    Divided {
                        RenameField(label: "Output name", stem: out.lastPathComponent.replacingOccurrences(of: "." + out.pathExtension, with: ""),
                                    ext: out.pathExtension.isEmpty ? "" : "." + out.pathExtension,
                                    hint: locked ? "The name is fixed while this file is converting." : "Enter to save, Escape to undo. The extension follows the route.",
                                    locked: locked) { store.rename(row, stem: $0) }
                    }
                    Text("This converter has no per-file settings.").css(13, .regular, T.t1).padding(.top, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apply to").css(12, .medium, T.t2)
                        HStack(spacing: 5) {
                            ScopeButton(title: "This file", on: store.applyScope == .this) { store.applyScope = .this }
                            ScopeButton(title: "Selected files", on: store.applyScope == .selected) { store.applyScope = .selected }
                            ScopeButton(title: "All \(row.from)", on: store.applyScope == .all) { store.applyScope = .all }
                        }
                        Text(store.applyScope == .this ? "Only this file will change." : store.applyScope == .selected ? "Changes apply to selected files." : "Changes apply to all matching files.")
                            .css(11, .regular, T.t3)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .scrollIndicators(.never)

            VStack(alignment: .leading, spacing: 12) {
                Text("Changes are ready to apply.").css(11, .regular, T.t3)
                HStack(spacing: 8) {
                    PanelButton(title: "Revert") { store.applyScope = .this }
                    PanelButton(title: "Apply changes", primary: true) { store.show("Changes applied") }
                        .disabled(store.sameKind(row).count < 2 && store.applyScope != .this)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
            .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
        }
    }
}

private struct ScopeButton: View {
    let title: String; let on: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).css(11, .regular, on ? T.accText : T.t3).lineLimit(1)
                .padding(.horizontal, 9).frame(height: 26)
                .background(RoundedRectangle(cornerRadius: 7).fill(on ? T.accTint : .clear))
                .overlay { if !on { RoundedRectangle(cornerRadius: 7).strokeBorder(T.sep2, lineWidth: 1) } }
        }.buttonStyle(PressStyle())
    }
}

// MARK: - a written file

struct HistoryPanel: View {
    let row: ConvertRow
    @ObservedObject var store: ConvertStore

    var body: some View {
        let missing = row.state == .missing
        let badge: (String, Color, Color) = switch row.state {
            case .done: ("On disk", T.okTint, T.okT)
            case .stopped: ("Stopped", T.warnTint, T.warnT)
            case .running: ("Converting", T.accTint, T.accText)
            default: ("Missing", T.quiet2, T.t3)
        }
        let name = row.name as NSString
        VStack(spacing: 0) {
            PanelSection(title: "Output details") {
                Text("\(row.from) → \(row.to)\(row.when.isEmpty ? "" : " · \(row.when)")")
                    .font(T.mono(11)).foregroundStyle(T.t2).padding(.top, 4)
            }
            HStack(spacing: 12) {
                FolderButton { store.reveal(row.outputPath) }
                VStack(alignment: .leading, spacing: 8) {
                    Text(row.name).css(13, .medium).lineLimit(1).truncationMode(.tail)
                    Text(badge.0).css(11, .medium, badge.2)
                        .padding(.horizontal, 7).frame(height: 19)
                        .background(RoundedRectangle(cornerRadius: 5).fill(badge.1))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .overlay(alignment: .bottom) { Rectangle().fill(T.sep).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        KV(k: "Output size", v: row.size.isEmpty ? "—" : row.size)
                        KV(k: "Conversion", v: row.conv.isEmpty ? "\(row.from.lowercased())-\(row.to.lowercased())" : row.conv)
                    }
                    Divided {
                        RenameField(label: "File name", stem: name.deletingPathExtension,
                                    ext: name.pathExtension.isEmpty ? "" : "." + name.pathExtension,
                                    hint: missing ? "The file is no longer where it was saved." : "Enter to save, Escape to undo. This renames the file on disk.",
                                    locked: missing) { store.rename(row, stem: $0) }
                    }
                    Divided { PathBlock(title: "Source file", path: row.sourcePath.isEmpty ? "Source path unavailable" : row.sourcePath) }
                    Divided { PathBlock(title: "Saved output", path: row.outputPath ?? "Output path unavailable") }
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
            .scrollIndicators(.never)

            VStack(spacing: 8) {
                PanelButton(title: "Queue again", primary: true) { store.requeueOne(row) }
                if !missing { PanelButton(title: "Show in folder") { store.reveal(row.outputPath) } }
            }
            .padding(EdgeInsets(top: 12, leading: 18, bottom: 16, trailing: 18))
            .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 1) }
        }
    }
}

private struct PathBlock: View {
    let title: String; let path: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeadCell(title)
            Text(path).font(T.mono(11)).foregroundStyle(T.t2).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }
    }
}

// MARK: - nothing selected

struct BatchPanel: View {
    @ObservedObject var store: ConvertStore
    var body: some View {
        let queue = store.queue
        let routes = Dictionary(grouping: queue, by: { "\($0.from) → \($0.to)" }).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
        VStack(spacing: 0) {
            PanelSection(title: queue.isEmpty ? "Nothing queued" : "Batch summary") {
                Text(queue.isEmpty ? "Drop files to begin." : "Select a row to edit that file on its own.").css(12, .regular, T.t2)
            }
            VStack(alignment: .leading, spacing: 16) {
                if queue.isEmpty {
                    Text("Once files are queued, this shows the batch at a glance — totals, destinations and shared settings. Select a row to edit that file on its own.")
                        .css(11, .regular, T.t3).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 8) {
                        KV(k: "Files queued", v: "\(queue.count)")
                        KV(k: "Need a helper", v: "\(queue.filter { $0.state == .blocked }.count)")
                        KV(k: "Destination", v: store.folder)
                    }
                    Divided {
                        HeadCell("Destinations").padding(.bottom, 8)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(routes, id: \.0) { route, n in
                                HStack(spacing: 8) {
                                    RouteChip(text: route)
                                    Text("\(n) file\(n == 1 ? "" : "s")").css(12, .regular, T.t2)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            Spacer(minLength: 0)
        }
    }
}

/// The 18pt strip on the work card's right edge that resizes the inspector.
/// Rules from panel-resize.js: capped at 520 (and window − 360); below 240 it
/// stops being a panel, and past half of that it snaps shut.
struct PanelResizeHandle: View {
    @Binding var width: Double
    @State private var start: Double?
    static let minWidth = 240.0, maxWidth = 520.0

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                }
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .global)
                        .onChanged { g in
                            let s = start ?? width
                            if start == nil { start = s }
                            let window = NSApp.keyWindow?.frame.width ?? 1200
                            let cap = max(Self.minWidth, min(Self.maxWidth, window - 360))
                            let raw = min(max(s - g.translation.width, 0), cap)
                            var t = Transaction(); t.disablesAnimations = true
                            withTransaction(t) { width = raw <= Self.minWidth / 2 ? 0 : max(raw, Self.minWidth).rounded() }
                        }
                        .onEnded { _ in start = nil }
                )
                .frame(width: geo.size.width)
        }
        .frame(width: 18)
        .offset(x: 9)
        .accessibilityLabel("Resize sidebar")
    }
}
