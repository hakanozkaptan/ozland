import Foundation

/// Localization keys for the application
enum LocalizationKey: String {
    case showHide
    case minimize
    case quit
    case theme
    case language
    case system
    case light
    case dark
    case english
    case turkish
    
    var rawValue: String {
        switch self {
        case .showHide: return "showHide"
        case .minimize: return "minimize"
        case .quit: return "quit"
        case .theme: return "theme"
        case .language: return "language"
        case .system: return "system"
        case .light: return "light"
        case .dark: return "dark"
        case .english: return "english"
        case .turkish: return "turkish"
        }
    }
}

/// Localized strings provider
enum Localization {
    private static let englishStrings: [String: String] = [
        LocalizationKey.showHide.rawValue: "Show/Hide",
        LocalizationKey.minimize.rawValue: "Minimize",
        LocalizationKey.quit.rawValue: "Quit",
        LocalizationKey.theme.rawValue: "Theme",
        LocalizationKey.language.rawValue: "Language",
        LocalizationKey.system.rawValue: "System",
        LocalizationKey.light.rawValue: "Light",
        LocalizationKey.dark.rawValue: "Dark",
        LocalizationKey.english.rawValue: "English",
        LocalizationKey.turkish.rawValue: "Turkish"
    ]
    
    private static let turkishStrings: [String: String] = [
        LocalizationKey.showHide.rawValue: "Göster/Gizle",
        LocalizationKey.minimize.rawValue: "Simge Durumuna Küçült",
        LocalizationKey.quit.rawValue: "Çıkış",
        LocalizationKey.theme.rawValue: "Tema",
        LocalizationKey.language.rawValue: "Dil",
        LocalizationKey.system.rawValue: "Sistem",
        LocalizationKey.light.rawValue: "Açık",
        LocalizationKey.dark.rawValue: "Koyu",
        LocalizationKey.english.rawValue: "English",
        LocalizationKey.turkish.rawValue: "Türkçe"
    ]
    
    static func localized(_ key: LocalizationKey, for language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishStrings[key.rawValue] ?? key.rawValue
        case .turkish:
            return turkishStrings[key.rawValue] ?? englishStrings[key.rawValue] ?? key.rawValue
        }
    }
}

