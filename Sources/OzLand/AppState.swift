import SwiftUI
import AppKit

/// Application theme options
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    /// Returns the NSAppearance corresponding to the theme
    var appearance: NSAppearance? {
        switch self {
        case .system:
            return nil // Use system default
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

/// Application language options
enum AppLanguage: String, CaseIterable {
    case english = "English"
    case turkish = "Turkish"
    
    /// Returns the locale string for the language
    var locale: String {
        switch self {
        case .english:
            return "en"
        case .turkish:
            return "tr"
        }
    }
    
    /// Returns a localized string for the given key
    func localized(_ key: LocalizationKey) -> String {
        Localization.localized(key, for: self)
    }
}

/// Manages application state including theme and language preferences
final class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var theme: AppTheme = .system {
        didSet {
            applyTheme()
        }
    }
    
    @Published var language: AppLanguage = .english {
        didSet {
            persistLanguage()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadSavedPreferences()
        applyTheme()
    }
    
    // MARK: - Private Methods
    
    private func loadSavedPreferences() {
        loadSavedTheme()
        loadSavedLanguage()
    }
    
    private func loadSavedTheme() {
        guard let savedThemeString = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.appTheme),
              let savedTheme = AppTheme(rawValue: savedThemeString) else {
            return
        }
        theme = savedTheme
    }
    
    private func loadSavedLanguage() {
        guard let savedLanguageString = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.appLanguage),
              let savedLanguage = AppLanguage(rawValue: savedLanguageString) else {
            return
        }
        language = savedLanguage
    }
    
    private func applyTheme() {
        NSApp.appearance = theme.appearance
        persistTheme()
    }
    
    private func persistTheme() {
        UserDefaults.standard.set(theme.rawValue, forKey: AppConstants.UserDefaultsKeys.appTheme)
    }
    
    private func persistLanguage() {
        UserDefaults.standard.set(language.rawValue, forKey: AppConstants.UserDefaultsKeys.appLanguage)
    }
}

