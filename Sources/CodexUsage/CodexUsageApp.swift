import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct CodexUsageApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var model = RateLimitViewModel()

  var body: some Scene {
    WindowGroup {
      TitaniumContentView(model: model)
    }
    .defaultSize(width: 720, height: 410)
    .windowResizability(.automatic)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }
  }
}

struct WindowConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async { configure(view.window) }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async { configure(nsView.window) }
  }

  private func configure(_ window: NSWindow?) {
    guard let window else { return }

    // R11: restore native macOS window chrome for reliable drag/resize, but make the
    // title bar visually transparent so the liquid-metal surface can extend beneath it.
    // The unwanted "transparent frame" is removed by making the liquid-metal panel
    // itself fill the complete content view, not by deleting the native window controls.
    window.styleMask.insert([
      .titled,
      .closable,
      .miniaturizable,
      .resizable,
      .fullSizeContentView,
    ])

    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.title = "Codex Usage"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.titlebarSeparatorStyle = .none
    window.isMovable = true
    window.isMovableByWindowBackground = true

    window.contentView?.wantsLayer = true
    window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

    window.collectionBehavior.remove(.fullScreenAuxiliary)
    window.collectionBehavior.insert(.fullScreenPrimary)

    window.standardWindowButton(.closeButton)?.isHidden = false
    window.standardWindowButton(.miniaturizeButton)?.isHidden = false
    window.standardWindowButton(.zoomButton)?.isHidden = false
    window.standardWindowButton(.closeButton)?.isEnabled = true
    window.standardWindowButton(.miniaturizeButton)?.isEnabled = true
    window.standardWindowButton(.zoomButton)?.isEnabled = true
  }
}
