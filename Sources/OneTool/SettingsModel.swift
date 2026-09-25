import SwiftUI

/// A 1:1 copy of SET_TABS / SET_DATA from converter/ui/features/settings/settings-view.js.
struct SetTab: Identifiable { let id, name, glyph: String }
enum RowKind { case toggle(Bool), select([String]), action(String) }
struct SetRow: Identifiable { let id, lab, sub: String; let kind: RowKind }
struct SetSection: Identifiable {
    let title: String; var mac = false; let rows: [SetRow]
    var id: String { title }
}

enum SettingsData {
    static let tabs: [SetTab] = [
        .init(id: "general", name: "General", glyph: "⚙"),
        .init(id: "conversions", name: "Conversions", glyph: "⇄"),
        .init(id: "editing", name: "Editing", glyph: "✎"),
        .init(id: "files", name: "Files and locations", glyph: "🗀"),
        .init(id: "helpers", name: "Helpers", glyph: "⚗"),
        .init(id: "shortcuts", name: "Shortcuts", glyph: "⌘"),
        .init(id: "advanced", name: "Advanced", glyph: "⌥"),
        .init(id: "about", name: "About", glyph: "☕"),
    ]
    static let order = ["general", "conversions", "editing", "files", "shortcuts", "advanced"]
    static let data: [String: [SetSection]] = [
        "general": [
            .init(title: "On launch", rows: [
                .init(id: "openWith", lab: "Open with", sub: "What One Tool shows when you start it.", kind: .select(["Last document", "File browser", "Empty window"])),
                .init(id: "restore", lab: "Restore open documents", sub: "Reopen everything that was open when you quit.", kind: .toggle(true)),
            ]),
            .init(title: "Appearance", rows: [
                .init(id: "theme", lab: "Theme", sub: "Follows the system unless you pick one.", kind: .select(["System", "Light", "Dark"])),
                .init(id: "density", lab: "Thumbnail size", sub: "Pages per row in the grid.", kind: .select(["Medium", "Small", "Large"])),
                .init(id: "anim", lab: "Animate view changes", sub: "Zoom between the grid and the reader.", kind: .toggle(true)),
            ]),
        ],
        "conversions": [
            .init(title: "Queue", rows: [
                .init(id: "autoStart", lab: "Start converting on drop", sub: "Files begin as soon as they land in the queue.", kind: .toggle(false)),
                .init(id: "parallel", lab: "Files at once", sub: "Higher is faster but uses more CPU.", kind: .select(["2", "1", "4", "8"])),
                .init(id: "onFail", lab: "When a file fails", sub: "Applies to the rest of the queue.", kind: .select(["Skip and continue", "Stop the queue", "Retry once"])),
            ]),
            .init(title: "Output", rows: [
                .init(id: "overwrite", lab: "If the output exists", sub: "Checked before anything is written.", kind: .select(["Add a number", "Overwrite", "Skip the file"])),
                .init(id: "notify", lab: "Notify when a batch finishes", sub: "A system notification, even when One Tool is in the background.", kind: .toggle(true)),
            ]),
            .init(title: "Finder", mac: true, rows: [
                .init(id: "quickActions", lab: "Right-click Quick Action", sub: "Adds “Convert with One Tool” to Quick Actions and Services wherever you right-click files. Results land beside the originals.", kind: .toggle(true)),
            ]),
        ],
        "editing": [
            .init(title: "Pages", rows: [
                .init(id: "confirmDel", lab: "Confirm before deleting pages", sub: "Ask once when more than one page is selected.", kind: .toggle(true)),
                .init(id: "rotStep", lab: "Rotation step", sub: "Applied by R and the toolbar buttons.", kind: .select(["90°", "180°", "15°"])),
                .init(id: "insertAt", lab: "Insert blank pages", sub: "Where a new page lands.", kind: .select(["After selection", "At the end", "Before selection"])),
            ]),
            .init(title: "Redaction", rows: [
                .init(id: "redactWarn", lab: "Warn before applying", sub: "Applying removes the content underneath permanently.", kind: .toggle(true)),
                .init(id: "redactScope", lab: "Default scope", sub: "Which pages a new block covers.", kind: .select(["This page", "All pages"])),
            ]),
        ],
        "files": [
            .init(title: "Saving", rows: [
                .init(id: "saveTo", lab: "Save new files to", sub: "Used by Extract and Save as new file.", kind: .select(["~/Converted", "Beside the original", "Ask each time"])),
                .init(id: "keepOrig", lab: "Keep the original", sub: "Never overwrite the file you opened.", kind: .toggle(true)),
                .init(id: "suffix", lab: "Name new files", sub: "Appended to the original name.", kind: .select(["— edited", "(1)", "Date stamp"])),
            ]),
            .init(title: "Recent", rows: [
                .init(id: "recentN", lab: "Remember recent files", sub: "Shown in the Convert list.", kind: .select(["20", "50", "None"])),
                .init(id: "clearRecent", lab: "Clear recent files", sub: "Removes the list. Files are untouched.", kind: .action("Clear")),
            ]),
        ],
        "shortcuts": [
            .init(title: "Global", rows: [
                .init(id: "paletteKey", lab: "Command palette", sub: "Opens from anywhere in the app.", kind: .select(["⌘K", "⌃K", "F1"])),
                .init(id: "settingsKey", lab: "Open settings", sub: "This window.", kind: .select(["⌘,", "⌃,", "None"])),
                .init(id: "zoomToggle", lab: "Grid and reader", sub: "Switches between all pages and a single page.", kind: .select(["⌃Space", "⌘0", "Tab"])),
            ]),
        ],
        "advanced": [
            .init(title: "Performance", rows: [
                .init(id: "cache", lab: "Page cache", sub: "More cache renders faster, uses more memory.", kind: .select(["512 MB", "256 MB", "2 GB"])),
                .init(id: "gpu", lab: "GPU rendering", sub: "Turn off if pages render incorrectly.", kind: .toggle(true)),
            ]),
            .init(title: "Diagnostics", rows: [
                .init(id: "logs", lab: "Verbose logging", sub: "Writes to the app log folder.", kind: .toggle(false)),
                .init(id: "reset", lab: "Reset all settings", sub: "Returns everything in this window to its default.", kind: .action("Reset")),
            ]),
        ],
    ]
}

/// Same storage contract as settings-actions.js: only values the user changed are
/// stored, so an unset key falls back to the row's default.
@MainActor final class SettingsStore: ObservableObject {
    private static let key = "onetool.settings"
    @Published private var vals: [String: String]
    init() { vals = UserDefaults.standard.dictionary(forKey: Self.key) as? [String: String] ?? [:] }

    func bool(_ row: SetRow) -> Bool {
        guard case .toggle(let on) = row.kind else { return false }
        return vals[row.id].map { $0 == "1" } ?? on
    }
    func string(_ row: SetRow) -> String {
        switch row.kind {
        case .select(let opts): return vals[row.id] ?? opts[0]
        case .action(let v): return v
        case .toggle: return ""
        }
    }
    func set(_ id: String, _ value: String) {
        vals[id] = value
        UserDefaults.standard.set(vals, forKey: Self.key)
        if id == "theme" { applyTheme() }
    }
    func toggle(_ row: SetRow) { set(row.id, bool(row) ? "0" : "1") }
    func reset() { vals = [:]; UserDefaults.standard.removeObject(forKey: Self.key); applyTheme() }

    func applyTheme() {
        switch vals["theme"] {
        case "Light": NSApp.appearance = NSAppearance(named: .aqua)
        case "Dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }
}
