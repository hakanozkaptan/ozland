import Testing
@testable import OzLand

/// Test suite for OzLand application
struct OzLandTests {
    
    // MARK: - AppTheme Tests
    
    @Test("AppTheme should have correct raw values")
    func testAppThemeRawValues() {
        #expect(AppTheme.system.rawValue == "System")
        #expect(AppTheme.light.rawValue == "Light")
        #expect(AppTheme.dark.rawValue == "Dark")
    }
    
    @Test("AppTheme should be created from raw values")
    func testAppThemeFromRawValue() {
        #expect(AppTheme(rawValue: "System") == .system)
        #expect(AppTheme(rawValue: "Light") == .light)
        #expect(AppTheme(rawValue: "Dark") == .dark)
        #expect(AppTheme(rawValue: "invalid") == nil)
    }
    
    // MARK: - AppLanguage Tests
    
    @Test("AppLanguage should have correct raw values")
    func testAppLanguageRawValues() {
        #expect(AppLanguage.english.rawValue == "English")
        #expect(AppLanguage.turkish.rawValue == "Turkish")
    }
    
    @Test("AppLanguage should be created from raw values")
    func testAppLanguageFromRawValue() {
        #expect(AppLanguage(rawValue: "English") == .english)
        #expect(AppLanguage(rawValue: "Turkish") == .turkish)
        #expect(AppLanguage(rawValue: "invalid") == nil)
    }
    
    // MARK: - Localization Tests
    
    @Test("English localization should return correct strings")
    func testLocalizationEnglish() {
        let language: AppLanguage = .english
        
        #expect(language.localized(.showHide) == "Show/Hide")
        #expect(language.localized(.minimize) == "Minimize")
        #expect(language.localized(.quit) == "Quit")
        #expect(language.localized(.theme) == "Theme")
        #expect(language.localized(.language) == "Language")
        #expect(language.localized(.system) == "System")
        #expect(language.localized(.light) == "Light")
        #expect(language.localized(.dark) == "Dark")
        #expect(language.localized(.english) == "English")
        #expect(language.localized(.turkish) == "Turkish")
    }
    
    @Test("Turkish localization should return correct strings")
    func testLocalizationTurkish() {
        let language: AppLanguage = .turkish
        
        #expect(language.localized(.showHide) == "Göster/Gizle")
        #expect(language.localized(.minimize) == "Simge Durumuna Küçült")
        #expect(language.localized(.quit) == "Çıkış")
        #expect(language.localized(.theme) == "Tema")
        #expect(language.localized(.language) == "Dil")
        #expect(language.localized(.system) == "Sistem")
        #expect(language.localized(.light) == "Açık")
        #expect(language.localized(.dark) == "Koyu")
        #expect(language.localized(.english) == "English")
        #expect(language.localized(.turkish) == "Türkçe")
    }
    
    // MARK: - LocalizationKey Tests
    
    @Test("LocalizationKey should have correct raw values")
    func testLocalizationKeyRawValues() {
        #expect(LocalizationKey.showHide.rawValue == "showHide")
        #expect(LocalizationKey.minimize.rawValue == "minimize")
        #expect(LocalizationKey.quit.rawValue == "quit")
        #expect(LocalizationKey.theme.rawValue == "theme")
        #expect(LocalizationKey.language.rawValue == "language")
        #expect(LocalizationKey.system.rawValue == "system")
        #expect(LocalizationKey.light.rawValue == "light")
        #expect(LocalizationKey.dark.rawValue == "dark")
        #expect(LocalizationKey.english.rawValue == "english")
        #expect(LocalizationKey.turkish.rawValue == "turkish")
    }
    
    // MARK: - Constants Tests
    
    @Test("Panel constants have expected values")
    func testPanelConstants() {
        #expect(AppConstants.Panel.collapsedWidth == 120)
        #expect(AppConstants.Panel.expandedWidth == 420)
        #expect(AppConstants.Panel.height == 120)
    }
    
    @Test("Artwork constants have expected values")
    func testArtworkConstants() {
        #expect(AppConstants.Artwork.compactSize == 48)
        #expect(AppConstants.Artwork.expandedSize == 60)
    }
    
    @Test("Equalizer constants have expected values")
    func testEqualizerConstants() {
        #expect(AppConstants.Equalizer.barCount == 4)
    }
    
    @Test("UserDefaults keys are correct")
    func testUserDefaultsKeys() {
        #expect(AppConstants.UserDefaultsKeys.appTheme == "appTheme")
        #expect(AppConstants.UserDefaultsKeys.appLanguage == "appLanguage")
    }
}
