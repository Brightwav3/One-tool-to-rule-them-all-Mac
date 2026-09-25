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
        .windowStyle(.hiddenTitleBar)
    }
}

/// index.html's .app: the top bar over the work card, with Settings as a sheet above both.
struct ContentView: View {
    @State private var page: Page = .convert
    @State private var settingsOpen = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopBar(page: $page, openSettings: { settingsOpen = true }, helperDot: Helpers.missing > 0)
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
            .ignoresSafeArea()

            if settingsOpen {
                SettingsSheet(isOpen: $settingsOpen).ignoresSafeArea().transition(.opacity)
            }
        }
        .background(WindowChrome())
        .focusEffectDisabled()
        .animation(.easeOut(duration: 0.25), value: settingsOpen)
        .background(Button("") { settingsOpen = true }.keyboardShortcut(",", modifiers: .command).hidden())
    }
}
