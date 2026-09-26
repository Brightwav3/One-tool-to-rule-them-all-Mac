import SwiftUI

@main
struct OneToolApp: App {
    @StateObject private var store = SettingsStore()
    init() { NSApplication.shared.setActivationPolicy(.regular) }

    var body: some Scene {
        Window("One Tool", id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear { store.applyTheme(); NSApp.activate(ignoringOtherApps: true) }
        }
        .defaultSize(width: 980, height: 700)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appSettings) { SettingsMenuItem() }
        }

        // Settings is its own window, opened above One Tool with the cog or ⌘,.
        Window("Settings", id: "settings") {
            SettingsWindowRoot()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

/// index.html's .app: the top bar over the work card, with Settings as a sheet above both.
struct ContentView: View {
    @EnvironmentObject var store: SettingsStore
    @State private var page: Page = .convert
    @Environment(\.openWindow) private var openWindow

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
        // The web top bar, hosted in the native toolbar so macOS draws the new traffic
        // lights, but with the per-item glass capsules turned off.
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 16) {
                    CogButton(dot: Helpers.missing > 0) { openWindow(id: "settings") }
                    ForEach(Page.allCases, id: \.self) { p in
                        NavButton(title: p.rawValue, active: p == page) { page = p }
                    }
                }
                .padding(.leading, 4)
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .principal) { SearchButton() }
                .sharedBackgroundVisibility(.hidden)
        }
        .toolbarBackground(T.bg, for: .windowToolbar)
        .navigationTitle("")
        .focusEffectDisabled()
    }
}

struct SettingsMenuItem: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Settings…") { openWindow(id: "settings") }.keyboardShortcut(",", modifiers: .command)
    }
}

/// The settings window's content; its ✕ and Esc close the window.
struct SettingsWindowRoot: View {
    @Environment(\.dismissWindow) private var dismissWindow
    var body: some View {
        ZStack(alignment: .top) {
            T.bg
            SettingsSheet(isOpen: Binding(get: { true }, set: { if !$0 { dismissWindow(id: "settings") } }), inWindow: true)
        }
        .ignoresSafeArea()
    }
}
