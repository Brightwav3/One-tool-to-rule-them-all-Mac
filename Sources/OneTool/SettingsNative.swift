import SwiftUI

/// Settings in the System Settings idiom: a sidebar of tinted icon tiles, a
/// searchable list, and grouped forms. The rows are the same SettingsData the
/// web app uses, so the two stay in step.
struct NativeSettings: View {
    @EnvironmentObject var store: SettingsStore
    @State private var tab: String? = "general"
    @State private var query = ""

    private static let icons: [String: (symbol: String, tint: Color)] = [
        "general": ("gearshape.fill", .gray),
        "conversions": ("arrow.left.arrow.right", .blue),
        "editing": ("pencil", .orange),
        "files": ("folder.fill", .cyan),
        "helpers": ("wrench.and.screwdriver.fill", .purple),
        "shortcuts": ("command", .gray),
        "advanced": ("slider.horizontal.3", .indigo),
        "about": ("cup.and.saucer.fill", .brown),
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $tab) {
                ForEach(SettingsData.tabs) { t in
                    Label {
                        HStack {
                            Text(t.name)
                            Spacer()
                            if t.id == "helpers", Helpers.missing > 0 {
                                Text("\(Helpers.missing)").font(.caption.weight(.semibold))
                                    .foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 1)
                                    .background(Capsule().fill(.orange))
                            }
                        }
                    } icon: {
                        IconTile(symbol: Self.icons[t.id]!.symbol, tint: Self.icons[t.id]!.tint)
                    }
                    .tag(t.id)
                }
            }
            .navigationSplitViewColumnWidth(215)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail
                .navigationTitle(query.isEmpty ? (SettingsData.tabs.first { $0.id == tab }?.name ?? "") : "Search results")
        }
        .searchable(text: $query, placement: .sidebar, prompt: "Search")
        .frame(minWidth: 715, minHeight: 470)
    }

    @ViewBuilder private var detail: some View {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty && tab == "about" {
            ScrollView { AboutBox().padding(20) }
        } else if q.isEmpty && tab == "helpers" {
            HelpersForm()
        } else {
            let source = q.isEmpty ? (SettingsData.data[tab ?? ""] ?? []) : SettingsData.order.flatMap { SettingsData.data[$0]! }
            let sections = source.compactMap { sec -> SetSection? in
                let rows = sec.rows.filter { q.isEmpty || "\($0.lab) \($0.sub)".lowercased().contains(q) }
                return rows.isEmpty ? nil : SetSection(title: sec.title, mac: sec.mac, rows: rows)
            }
            if sections.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                Form {
                    ForEach(sections) { sec in
                        Section(sec.title) {
                            ForEach(sec.rows) { row in SettingRow(row: row) }
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
    }
}

/// The rounded, tinted square System Settings puts behind each sidebar symbol.
struct IconTile: View {
    let symbol: String; let tint: Color
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tint.gradient))
    }
}

struct SettingRow: View {
    let row: SetRow
    @EnvironmentObject var store: SettingsStore

    var body: some View {
        switch row.kind {
        case .toggle:
            Toggle(isOn: Binding(get: { store.bool(row) }, set: { _ in store.toggle(row) })) { label }
                .toggleStyle(.switch)
        case .select(let opts):
            Picker(selection: Binding(get: { store.string(row) }, set: { store.set(row.id, $0) })) {
                ForEach(opts, id: \.self) { Text($0).tag($0) }
            } label: { label }
            .pickerStyle(.menu)
        case .action(let title):
            LabeledContent { Button("\(title)…") { if row.id == "reset" { store.reset() } } } label: { label }
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.lab)
            Text(row.sub).font(.callout).foregroundStyle(.secondary)
        }
    }
}

struct HelpersForm: View {
    @State private var copied: String?
    @State private var tick = 0
    var body: some View {
        let all = Helpers.all, missing = Helpers.missing
        Form {
            Section {
                LabeledContent {
                    HStack {
                        Button("Get Homebrew…") { NSWorkspace.shared.open(URL(string: "https://brew.sh")!) }
                        Button("Re-scan") { Helpers.rescan(); tick += 1 }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(missing > 0 ? "\(all.count - missing) of \(all.count) installed" : "All \(all.count) installed")
                        Text("Free, standard tools. Install a missing helper and every conversion that needs it turns on.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Helpers") {
                ForEach(all) { h in
                    DisclosureGroup {
                        LabeledContent("Unlocks") { Text(h.unlocks.joined(separator: ", ")).foregroundStyle(.secondary) }
                        LabeledContent {
                            Button(copied == h.name ? "Copied" : "Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(h.cmd, forType: .string)
                                copied = h.name
                            }
                        } label: { Text(h.cmd).font(.system(.callout, design: .monospaced)).textSelection(.enabled) }
                    } label: {
                        HStack {
                            Circle().fill(h.found ? Color.green : Color.orange).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.name)
                                Text("\(h.unlocks.count) conversions").font(.callout).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(h.found ? "Installed" : "Missing").foregroundStyle(h.found ? .green : .orange)
                        }
                    }
                }
            }
            .id(tick)
        }
        .formStyle(.grouped)
    }
}
