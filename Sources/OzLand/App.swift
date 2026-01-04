import SwiftUI
import AppKit
import QuartzCore

@main
struct OzLandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    
    private var spotifyManager: SpotifyManager?
    private var panelManager: PanelManager?
    private var statusItem: NSStatusItem?
    private var monitoringTimer: Timer?
    let appState = AppState()
    
    private enum Constants {
        static let monitoringInterval = AppConstants.Monitoring.spotifyCheckInterval
        static let statusBarIconName = AppConstants.StatusBar.iconName
        static let statusBarAccessibilityDescription = AppConstants.StatusBar.accessibilityDescription
    }
    
    // MARK: - NSApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeManagers()
        setupStatusBar()
        startMonitoringSpotify()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    // MARK: - Setup
    
    private func initializeManagers() {
        let spotifyManager = SpotifyManager()
        let panelManager = PanelManager()
        
        self.spotifyManager = spotifyManager
        self.panelManager = panelManager
        
        panelManager.setupPanel(spotifyManager: spotifyManager, appState: appState)
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        if let image = NSImage(systemSymbolName: Constants.statusBarIconName, accessibilityDescription: Constants.statusBarAccessibilityDescription) {
            button.image = image
            button.image?.isTemplate = true
        } else if let fallbackImage = NSImage(systemSymbolName: "music.note", accessibilityDescription: Constants.statusBarAccessibilityDescription) {
            button.image = fallbackImage
            button.image?.isTemplate = true
        } else {
            button.title = "♪"
        }

        let menu = createMenu()
        statusItem?.menu = menu
        updateLanguageMenuItems()
    }
    
    // MARK: - Menu Creation
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(createShowHideMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createLanguageSubmenu())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createThemeSubmenu())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createMinimizeMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createQuitMenuItem())
        
        return menu
    }
    
    private func createShowHideMenuItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: appState.language.localized(.showHide),
            action: #selector(toggleVisibility),
            keyEquivalent: ""
        )
        item.target = self
        return item
    }
    
    private func createLanguageSubmenu() -> NSMenuItem {
        let submenu = NSMenu()
        
        let englishItem = NSMenuItem(
            title: appState.language.localized(.english),
            action: #selector(setEnglish),
            keyEquivalent: ""
        )
        englishItem.target = self
        englishItem.state = appState.language == .english ? .on : .off
        submenu.addItem(englishItem)
        
        let turkishItem = NSMenuItem(
            title: appState.language.localized(.turkish),
            action: #selector(setTurkish),
            keyEquivalent: ""
        )
        turkishItem.target = self
        turkishItem.state = appState.language == .turkish ? .on : .off
        submenu.addItem(turkishItem)
        
        let menuItem = NSMenuItem(
            title: appState.language.localized(.language),
            action: nil,
            keyEquivalent: ""
        )
        menuItem.submenu = submenu
        return menuItem
    }
    
    private func createThemeSubmenu() -> NSMenuItem {
        let submenu = NSMenu()
        
        let systemItem = createThemeMenuItem(
            title: appState.language.localized(.system),
            action: #selector(setSystemTheme),
            isSelected: appState.theme == .system
        )
        submenu.addItem(systemItem)
        
        let lightItem = createThemeMenuItem(
            title: appState.language.localized(.light),
            action: #selector(setLightTheme),
            isSelected: appState.theme == .light
        )
        submenu.addItem(lightItem)
        
        let darkItem = createThemeMenuItem(
            title: appState.language.localized(.dark),
            action: #selector(setDarkTheme),
            isSelected: appState.theme == .dark
        )
        submenu.addItem(darkItem)
        
        let menuItem = NSMenuItem(
            title: appState.language.localized(.theme),
            action: nil,
            keyEquivalent: ""
        )
        menuItem.submenu = submenu
        return menuItem
    }
    
    private func createThemeMenuItem(title: String, action: Selector, isSelected: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isSelected ? .on : .off
        return item
    }
    
    private func createMinimizeMenuItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: appState.language.localized(.minimize),
            action: #selector(minimizePanel),
            keyEquivalent: "m"
        )
        item.target = self
        item.keyEquivalentModifierMask = [.command]
        return item
    }
    
    private func createQuitMenuItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: appState.language.localized(.quit),
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        item.target = self
        item.keyEquivalentModifierMask = [.command]
        return item
    }
    
    // MARK: - Actions
    
    @objc private func toggleVisibility() {
        panelManager?.toggleVisibility()
    }
    
    @objc private func minimizePanel() {
        panelManager?.hide()
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func setSystemTheme() {
        appState.theme = .system
        updateThemeMenuStates()
        updateAllMenuItems()
    }
    
    @objc private func setLightTheme() {
        appState.theme = .light
        updateThemeMenuStates()
        updateAllMenuItems()
    }
    
    @objc private func setDarkTheme() {
        appState.theme = .dark
        updateThemeMenuStates()
        updateAllMenuItems()
    }
    
    @objc private func setEnglish() {
        appState.language = .english
        updateLanguageMenuStates()
        updateLanguageMenuItems()
    }
    
    @objc private func setTurkish() {
        appState.language = .turkish
        updateLanguageMenuStates()
        updateLanguageMenuItems()
    }
    
    private func updateThemeMenuStates() {
        guard let menu = statusItem?.menu else { return }
        
        for item in menu.items {
            if let themeMenu = item.submenu, item.action == nil {
                for themeItem in themeMenu.items {
                    if themeItem.action == #selector(setSystemTheme) {
                        themeItem.state = appState.theme == .system ? .on : .off
                    } else if themeItem.action == #selector(setLightTheme) {
                        themeItem.state = appState.theme == .light ? .on : .off
                    } else if themeItem.action == #selector(setDarkTheme) {
                        themeItem.state = appState.theme == .dark ? .on : .off
                    }
                }
            }
        }
    }
    
    private func updateLanguageMenuStates() {
        guard let menu = statusItem?.menu,
              let languageMenuItem = findLanguageMenuItem(in: menu),
              let languageMenu = languageMenuItem.submenu else {
            return
        }
        
        for item in languageMenu.items {
            if item.action == #selector(setEnglish) {
                item.state = appState.language == .english ? .on : .off
            } else if item.action == #selector(setTurkish) {
                item.state = appState.language == .turkish ? .on : .off
            }
        }
    }
    
    // MARK: - Menu Updates
    
    private func updateLanguageMenuItems() {
        guard let menu = statusItem?.menu,
              let languageMenuItem = findLanguageMenuItem(in: menu),
              let languageMenu = languageMenuItem.submenu else {
            return
        }
        
        updateLanguageMenu(languageMenuItem: languageMenuItem, languageMenu: languageMenu)
        updateAllMenuItems()
    }
    
    private func findLanguageMenuItem(in menu: NSMenu) -> NSMenuItem? {
        menu.items.first { item in
            item.action == nil && item.submenu != nil &&
            (item.title.contains("Dil") || item.title.contains("Language"))
        }
    }
    
    private func updateLanguageMenu(languageMenuItem: NSMenuItem, languageMenu: NSMenu) {
        languageMenuItem.title = appState.language.localized(.language)
        
        for item in languageMenu.items {
            if item.action == #selector(setEnglish) {
                item.title = appState.language.localized(.english)
                item.state = appState.language == .english ? .on : .off
            } else if item.action == #selector(setTurkish) {
                item.title = appState.language.localized(.turkish)
                item.state = appState.language == .turkish ? .on : .off
            }
        }
    }
    
    private func updateAllMenuItems() {
        guard let menu = statusItem?.menu else { return }
        
        for item in menu.items {
            updateMenuItem(item)
        }
    }
    
    private func updateMenuItem(_ item: NSMenuItem) {
        if item.action == #selector(toggleVisibility) {
            item.title = appState.language.localized(.showHide)
        } else if item.action == #selector(minimizePanel) {
            item.title = appState.language.localized(.minimize)
        } else if item.action == #selector(quitApplication) {
            item.title = appState.language.localized(.quit)
        } else if let themeMenu = item.submenu, item.action == nil {
            updateThemeSubmenu(item: item, themeMenu: themeMenu)
        }
    }
    
    private func updateThemeSubmenu(item: NSMenuItem, themeMenu: NSMenu) {
        item.title = appState.language.localized(.theme)
        
        for themeItem in themeMenu.items {
            if themeItem.action == #selector(setSystemTheme) {
                themeItem.title = appState.language.localized(.system)
                themeItem.state = appState.theme == .system ? .on : .off
            } else if themeItem.action == #selector(setLightTheme) {
                themeItem.title = appState.language.localized(.light)
                themeItem.state = appState.theme == .light ? .on : .off
            } else if themeItem.action == #selector(setDarkTheme) {
                themeItem.title = appState.language.localized(.dark)
                themeItem.state = appState.theme == .dark ? .on : .off
            }
        }
    }
    
    // MARK: - Monitoring
    
    private func startMonitoringSpotify() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: Constants.monitoringInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.panelManager?.updateVisibility()
            }
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        panelManager?.hide()
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
}
