import Cocoa
import Foundation

// Main entry point for the Audio Sorter application
let app = NSApplication.shared
app.setActivationPolicy(.regular) // Ensure it appears in Dock and can become active
let delegate = AppDelegate()
app.delegate = delegate
app.run()
