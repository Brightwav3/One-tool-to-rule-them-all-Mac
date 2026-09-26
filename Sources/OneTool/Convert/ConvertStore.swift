import SwiftUI
import AppKit

/// A converter as /api/tools describes it.
struct Tool: Identifiable, Hashable {
    enum State: String { case ready, helper, soon }
    let id, from, to: String
    var state: State
    let cat: String
    var stateLabel: String { state == .ready ? "Ready" : state == .helper ? "Needs helper" : "Not built yet" }
}

struct Toast: Equatable { let title: String; var ok = true; let id = UUID() }

/// Everything the Convert page shows and does. Checkpoint 2 keeps it local; the
/// backend calls replace the bodies of these methods in checkpoint 3.
@MainActor final class ConvertStore: ObservableObject {
    @Published var rows: [ConvertRow] = SampleData.rows
    @Published var tools: [Tool] = SampleData.tools
    @Published var filter: Filter = .all
    @Published var sort: Sort = .newest

    // Ticked boxes (any row) and the row selection (queue rows, or one history row).
    @Published var checked: Set<String> = []
    private var checkAnchor: String?
    @Published var selected: Set<String> = []
    private var selectAnchor: String?
    @Published var selectedHistory: String?
    /// The queue row the inspector edits (selectedId in app-state.js).
    @Published var focused: String?
    enum ApplyScope { case this, selected, all }
    @Published var applyScope: ApplyScope = .this

    @Published var pickerFor: String?
    @Published var scopeAll = false
    @Published var folder = "~/Converted"
    @Published var recentFolders: [String] = ["~/Converted", "~/Desktop", "~/Documents/Comics"]
    @Published var folderMenuOpen = false
    @Published var toast: Toast?

    var visible: [ConvertRow] {
        let rank: [ConvertRow.State] = [.running, .queued, .blocked, .idle, .error, .stopped]
        let r = { (x: ConvertRow) in (rank.firstIndex(of: x.state) ?? 98) + 1 }
        return rows.enumerated().filter { filter.matches($0.element) }.sorted { a, b in
            if r(a.element) != r(b.element) { return r(a.element) < r(b.element) }
            switch sort {
            case .name: return a.element.name.localizedCompare(b.element.name) == .orderedAscending
            case .oldest: return a.offset > b.offset
            case .largest: return a.element.bytes > b.element.bytes
            case .newest: return a.offset < b.offset
            }
        }.map(\.element)
    }

    func closeMenus() { pickerFor = nil; folderMenuOpen = false }

    /// history-sort cycles Newest → Oldest → Name → Largest.
    func cycleSort() {
        let all = Sort.allCases
        sort = all[(all.firstIndex(of: sort)! + 1) % all.count]
    }

    /// updateSelection() from selection-state.js: shift extends from the anchor,
    /// ⌘ toggles, a plain click selects just this row.
    private func update(_ ids: [String], _ current: Set<String>, _ anchor: String?, _ target: String, shift: Bool, toggle: Bool) -> (Set<String>, String?) {
        if shift, let anchor, let a = ids.firstIndex(of: anchor), let t = ids.firstIndex(of: target) {
            return (Set(ids[min(a, t)...max(a, t)]), anchor)
        }
        var next = current
        if toggle { if next.contains(target) { next.remove(target) } else { next.insert(target) }; return (next, target) }
        return ([target], target)
    }

    func click(_ row: ConvertRow) {
        closeMenus()
        let flags = NSEvent.modifierFlags
        if NSApp.currentEvent?.clickCount == 2 { return open(row) }
        if row.kind == .queue {
            (selected, selectAnchor) = update(rows.filter { $0.kind == .queue }.map(\.id), selected, selectAnchor, row.id,
                                             shift: flags.contains(.shift), toggle: flags.contains(.command))
            selectedHistory = nil
            focused = selected.contains(row.id) ? row.id : selected.first
        } else {
            (checked, checkAnchor) = update(visible.filter { $0.kind == .history }.map(\.id), checked, checkAnchor, row.id,
                                           shift: flags.contains(.shift), toggle: flags.contains(.command))
            selectedHistory = row.id
            selected = []; selectAnchor = nil; focused = nil
        }
    }

    /// Ticking a box is about the list, so a shift-range covers every visible row.
    func check(_ row: ConvertRow) {
        closeMenus()
        (checked, checkAnchor) = update(visible.map(\.id), checked, checkAnchor, row.id,
                                       shift: NSEvent.modifierFlags.contains(.shift), toggle: true)
    }
    func checkAll() {
        let ids = Set(visible.map(\.id))
        if ids.isSubset(of: checked) { checked.subtract(ids) } else { checked.formUnion(ids) }
    }

    var focusedRow: ConvertRow? { rows.first { $0.id == focused && $0.kind == .queue } }
    var historyRow: ConvertRow? { rows.first { $0.id == selectedHistory } }
    var queue: [ConvertRow] { rows.filter { $0.kind == .queue } }

    /// Renaming names the output; the extension belongs to the route.
    func rename(_ row: ConvertRow, stem: String) {
        guard let i = rows.firstIndex(where: { $0.id == row.id }), let out = rows[i].outputPath else { return }
        let ns = out as NSString
        rows[i].outputPath = (ns.deletingLastPathComponent as NSString).appendingPathComponent(stem + "." + ns.pathExtension)
        if row.kind == .history { rows[i].name = stem + "." + ns.pathExtension }
        show("Renamed")
    }
    func requeueOne(_ row: ConvertRow) {
        guard let i = rows.firstIndex(where: { $0.id == row.id }) else { return }
        rows[i].kind = .queue; rows[i].state = .idle; rows[i].size = ""; rows[i].when = ""
        selectedHistory = nil; checked.remove(row.id)
        show("Queued again")
    }
    func reveal(_ path: String?) {
        guard let path else { return }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        if FileManager.default.fileExists(atPath: url.path) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        else { show("The file isn't there anymore", ok: false) }
    }

    func open(_ row: ConvertRow) {
        guard let path = row.outputPath else { return }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        if FileManager.default.fileExists(atPath: url.path) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        else { show("The file isn't there anymore", ok: false) }
    }

    // MARK: route picker
    func togglePicker(_ row: ConvertRow) {
        folderMenuOpen = false
        if !selected.contains(row.id) { selected = [row.id]; selectAnchor = row.id }
        pickerFor = pickerFor == row.id ? nil : row.id
    }
    func candidates(for row: ConvertRow) -> [Tool] {
        let rank: [Tool.State: Int] = [.ready: 0, .helper: 1, .soon: 2]
        return tools.filter { $0.from == row.from }.sorted { (rank[$0.state]!, $0.to) < (rank[$1.state]!, $1.to) }
    }
    var destinationCount: Int { Set(tools.map(\.to)).count }
    func sameKind(_ row: ConvertRow) -> [ConvertRow] { rows.filter { $0.kind == .queue && $0.from == row.from } }
    func scopeLabel(_ row: ConvertRow) -> String { scopeAll ? allScopeLabel(row) : "This file" }
    func allScopeLabel(_ row: ConvertRow) -> String {
        let n = sameKind(row).count
        return n == 1 ? "The 1 \(row.from) file" : "All \(n) \(row.from) files"
    }
    func choose(_ tool: Tool, for row: ConvertRow) {
        let targets = scopeAll ? sameKind(row).map(\.id) : [row.id]
        for i in rows.indices where targets.contains(rows[i].id) {
            rows[i].to = tool.to
            rows[i].conv = tool.id
            if rows[i].state == .blocked || rows[i].state == .done { rows[i].state = .idle; rows[i].helper = nil }
            if tool.state == .helper { rows[i].state = .blocked; rows[i].helper = "a helper" }
        }
        pickerFor = nil
        show(targets.count == 1 ? "Route changed" : "Route changed for \(targets.count) files")
    }

    // MARK: destination
    func pickFolder() {
        closeMenus()
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true
        panel.prompt = "Save here"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let path = (url.path as NSString).abbreviatingWithTildeInPath
        setFolder(path)
        show("Destination updated")
    }
    func setFolder(_ path: String) {
        folder = path
        recentFolders.removeAll { $0 == path }
        recentFolders.insert(path, at: 0)
        folderMenuOpen = false
    }
    func forget(_ path: String) { recentFolders.removeAll { $0 == path } }

    // MARK: bulk actions on ticked rows
    func requeue() {
        for i in rows.indices where checked.contains(rows[i].id) {
            rows[i].kind = .queue; rows[i].state = .idle; rows[i].size = ""; rows[i].when = ""
        }
        show("Requeued \(checked.count)"); checked = []
    }
    func delete() {
        let n = checked.count
        rows.removeAll { checked.contains($0.id) }
        selected.subtract(checked); checked = []
        show("Deleted \(n)")
    }

    func show(_ title: String, ok: Bool = true) {
        let t = Toast(title: title, ok: ok)
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.35)) { toast = t }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) { [weak self] in
            guard self?.toast?.id == t.id else { return }
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.15)) { self?.toast = nil }
        }
    }
}
