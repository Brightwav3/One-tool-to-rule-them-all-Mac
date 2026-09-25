import SwiftUI

@main
struct OneToolApp: App {
    @StateObject private var store = SettingsStore()
    init() { NSApplication.shared.setActivationPolicy(.regular) }

    var body: some Scene {
        WindowGroup("One Tool") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear { store.applyTheme(); NSApp.activate(ignoringOtherApps: true) }
        }
        .defaultSize(width: 980, height: 700)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { NotificationCenter.default.post(name: .openSettings, object: nil) }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

/// index.html's .app: the top bar over the work card, with Settings as a sheet above both.
struct ContentView: View {
    @EnvironmentObject var store: SettingsStore
    @State private var page: Page = .convert
    @State private var settingsOpen = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Group {
                    switch page {
                    case .convert: ConvertView()
                    case .creator:
                        Text("Creator isn't ported yet.").css(13, .regular, T.t3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(T.surface)
                .clipShape(UnevenRoundedRectangle(topTrailingRadius: 14, style: .continuous))
                .overlay(UnevenRoundedRectangle(topTrailingRadius: 14, style: .continuous).stroke(T.sep, lineWidth: 1).padding(.leading, -1).padding(.bottom, -1))
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                .shadow(color: .black.opacity(0.08), radius: 11, y: 8)
            }
            .background(T.bg)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                CogButton(dot: Helpers.missing > 0) { settingsOpen = true }
            }
            ToolbarItem(placement: .principal) {
                Picker("Page", selection: $page) {
                    ForEach(Page.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).fixedSize()
            }
            ToolbarItem(placement: .primaryAction) { SearchButton() }
        }
        .navigationTitle("")
        .focusEffectDisabled()
        .sheet(isPresented: $settingsOpen) {
            SettingsSheet(isOpen: $settingsOpen).environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in settingsOpen = true }
    }
}

extension Notification.Name { static let openSettings = Notification.Name("onetool.openSettings") }
