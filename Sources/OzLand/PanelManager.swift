import AppKit
import SwiftUI
import QuartzCore
import Combine

/// Manages the floating NSPanel window for Dynamic Island UI
final class PanelManager: ObservableObject {
    // MARK: - Properties
    
    private var panel: NSPanel?
    private var hostingView: Any?
    weak var spotifyManager: SpotifyManager?
    private var screenChangeObserver: NSObjectProtocol?
    private var themeObserver: AnyCancellable?
    private var isManuallyHidden: Bool = false
    
    private enum Constants {
        static let collapsedWidth = AppConstants.Panel.collapsedWidth
        static let expandedWidth = AppConstants.Panel.expandedWidth
        static let height = AppConstants.Panel.height
        static let verticalOffset = AppConstants.Panel.verticalOffset
        static let animationDuration = AppConstants.Animation.panelResizeDuration
        static let visibilityUpdateDelay = AppConstants.Monitoring.visibilityUpdateDelay
    }
    
    // MARK: - Setup
    
    func setupPanel(spotifyManager: SpotifyManager, appState: AppState) {
        self.spotifyManager = spotifyManager
        
        let panel = createPanel()
        configurePanel(panel)
        setupContentView(panel, spotifyManager: spotifyManager, appState: appState)
        
        self.panel = panel
        
        centerPanel(panel)
        show()
        startMonitoringScreenChanges()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.visibilityUpdateDelay) { [weak self] in
            self?.updateVisibility()
        }
    }
    
    private func createPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Constants.collapsedWidth, height: Constants.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = false
        
        return panel
    }
    
    private func configurePanel(_ panel: NSPanel) {
        guard let contentView = panel.contentView else { return }
        
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    private func setupContentView(_ panel: NSPanel, spotifyManager: SpotifyManager, appState: AppState) {
        updateContentView(panel: panel, spotifyManager: spotifyManager, appState: appState)
        
        // Apply appearance to panel
        panel.appearance = appState.theme.appearance
        
        // Listen to theme changes
        themeObserver = appState.$theme
            .dropFirst() // Skip initial value
            .sink { [weak self] theme in
                guard let self = self, let panel = self.panel else { return }
                DispatchQueue.main.async {
                    panel.appearance = theme.appearance
                    // Update the hosting view
                    self.updateContentView(panel: panel, spotifyManager: spotifyManager, appState: appState)
                }
            }
    }
    
    private func updateContentView(panel: NSPanel, spotifyManager: SpotifyManager, appState: AppState) {
        let contentView = DynamicIslandView(appState: appState)
            .environmentObject(spotifyManager)
            .environmentObject(self)
            .preferredColorScheme(appState.theme == .system ? nil : (appState.theme == .dark ? .dark : .light))
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]
        
        if let existingContentView = panel.contentView {
            hostingView.frame = existingContentView.bounds
        } else {
            hostingView.frame = panel.contentView!.bounds
        }
        
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        panel.contentView = hostingView
        self.hostingView = hostingView
    }
    
    // MARK: - Positioning
    
    private func centerPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let screenWidth = screen.frame.width
        let panelWidth = panel.frame.width
        let x = screen.frame.minX + (screenWidth / 2) - (panelWidth / 2)
        // Always align to top (maxY is the top of the screen in Cocoa coordinate system)
        let y = screen.frame.maxY - Constants.height
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func updatePosition() {
        guard let panel = panel else { return }
        centerPanel(panel)
    }
    
    func startMonitoringScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePosition()
        }
    }
    
    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        themeObserver?.cancel()
    }
    
    // MARK: - Visibility
    
    func show() {
        guard let panel = panel else { return }
        isManuallyHidden = false
        panel.orderFront(nil)
        panel.makeKeyAndOrderFront(nil)
        centerPanel(panel)
    }
    
    func hide() {
        isManuallyHidden = true
        panel?.orderOut(nil)
    }
    
    func toggleVisibility() {
        if isManuallyHidden {
            show()
        } else {
            hide()
        }
    }
    
    func updateVisibility() {
        // If manually hidden, don't auto-show even if Spotify is running
        guard !isManuallyHidden else { return }
        
        guard isSpotifyRunning() else {
            panel?.orderOut(nil)
            return
        }
        show()
    }
    
    private func isSpotifyRunning() -> Bool {
        let script = """
        tell application "System Events"
            return (name of processes) contains "Spotify"
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return false }
        
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        
        return error == nil && result.booleanValue
    }
    
    // MARK: - Interactions
    
    func expand() {
        guard let panel = panel,
              let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        // Prevent redundant expansion
        if panel.frame.width == Constants.expandedWidth { return }
        
        let currentFrame = panel.frame
        let screenWidth = screen.frame.width
        let newWidth = Constants.expandedWidth
        let newX = screen.frame.minX + (screenWidth / 2) - (newWidth / 2)
        
        animatePanelResize(
            panel: panel,
            to: NSRect(x: newX, y: currentFrame.origin.y, width: newWidth, height: Constants.height)
        )
    }
    
    func collapse() {
        guard let panel = panel,
              let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        // Prevent redundant collapse
        if panel.frame.width == Constants.collapsedWidth { return }
        
        let currentFrame = panel.frame
        let screenWidth = screen.frame.width
        let newWidth = Constants.collapsedWidth
        let newX = screen.frame.minX + (screenWidth / 2) - (newWidth / 2)
        
        animatePanelResize(
            panel: panel,
            to: NSRect(x: newX, y: currentFrame.origin.y, width: newWidth, height: Constants.height)
        )
    }
    
    private func animatePanelResize(panel: NSPanel, to frame: NSRect) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }
    
    func openSpotify() {
        let script = """
        tell application "Spotify"
            activate
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
    }
}
