import SwiftUI

@main
struct OneToolApp: App {
    @StateObject private var store = SettingsStore()
    init() { NSApplication.shared.setActivationPolicy(.regular) }

    var body: some Scene {
        WindowGroup("One Tool") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 801, minHeight: 491)
                .onAppear { store.applyTheme(); NSApp.activate(ignoringOtherApps: true) }
        }
        .defaultSize(width: 980, height: 700)
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    @State private var settingsOpen = true
    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("One Tool to Rule Them All").css(25, .semibold)
                Text("Native rewrite — only Settings is ported so far.").css(13, .regular, T.t3)
                SecondaryButton("Open settings  ⌘,") { settingsOpen = true }
            }
            if settingsOpen {
                SettingsSheet(isOpen: $settingsOpen)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: settingsOpen)
        .background(Button("") { settingsOpen = true }.keyboardShortcut(",", modifiers: .command).hidden())
    }
}
