import SwiftUI

@main
struct OneToolApp: App {
    var body: some Scene {
        WindowGroup("One Tool") {
            ContentView()
                .frame(minWidth: 640, minHeight: 420)
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                .font(.system(size: 48))
            Text("One Tool to Rule Them All")
                .font(.title)
            Text("Drop files here to convert — native macOS rewrite in progress.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
