import AppKit
import Foundation

struct CodexExecutableLocator {
  static func locate() -> URL? {
    let fm = FileManager.default

    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex") {
      let bundled = appURL.appendingPathComponent("Contents/Resources/codex")
      if fm.isExecutableFile(atPath: bundled.path) {
        return bundled
      }
    }

    let standard = URL(fileURLWithPath: "/Applications/ChatGPT.app/Contents/Resources/codex")
    if fm.isExecutableFile(atPath: standard.path) {
      return standard
    }

    return nil
  }
}
