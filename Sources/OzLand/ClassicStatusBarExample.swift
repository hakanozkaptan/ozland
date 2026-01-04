import AppKit
import SwiftUI

/// Classic NSStatusBar approach example
/// This file provides a reference for those who want to use NSStatusBar/NSStatusItem instead of MenuBarExtra
class ClassicStatusBarManager {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func setup() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Set icon
        button.image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "Dynamic Island")
        button.image?.isTemplate = true // Adapt to menu bar theme
        
        // Set click action
        button.action = #selector(togglePopover)
        button.target = self
        
        // Create popover (popup window)
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 500, height: 400)
        popover?.behavior = .transient // Closes when clicking outside
        popover?.contentViewController = NSHostingController(rootView: ContentView())
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button,
              let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Show popover below the button
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Make popover the active window
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// Usage example:
// In AppDelegate:
// let statusBarManager = ClassicStatusBarManager()
// statusBarManager.setup()

