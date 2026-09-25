import SwiftUI
import AppKit

/// Electron's `titleBarStyle:'hidden'` + `trafficLightPosition:{14,14}`: the lights
/// sit inside the 44px top bar, left-aligned at 14 and centred vertically.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = ChromeView()
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class ChromeView: NSView {
        private var observers: [NSObjectProtocol] = []
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let w = window else { return }
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.styleMask.insert(.fullSizeContentView)
            w.backgroundColor = NSColor(T.bg)
            observers.forEach(NotificationCenter.default.removeObserver)
            observers = [NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification, NSWindow.didExitFullScreenNotification]
                .map { NotificationCenter.default.addObserver(forName: $0, object: w, queue: .main) { [weak self] _ in self?.place() } }
            DispatchQueue.main.async { self.place() }
        }
        private func place() {
            guard let w = window, let close = w.standardWindowButton(.closeButton),
                  let container = close.superview?.superview else { return }
            let bar: CGFloat = 44
            var f = container.frame
            f.size.height = bar
            f.origin.y = w.frame.height - bar
            container.frame = f
            for (i, kind) in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton].enumerated() {
                guard let b = w.standardWindowButton(kind) else { continue }
                b.setFrameOrigin(NSPoint(x: 14 + CGFloat(i) * 20, y: (bar - b.frame.height) / 2))
            }
        }
    }
}
