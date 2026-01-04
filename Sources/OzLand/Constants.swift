import Foundation
import SwiftUI

/// Application-wide constants
enum AppConstants {
    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let appTheme = "appTheme"
        static let appLanguage = "appLanguage"
    }
    
    /// Status bar configuration
    enum StatusBar {
        static let iconName = "waveform"
        static let accessibilityDescription = "Dynamic Island"
    }
    
    /// Panel dimensions and layout
    enum Panel {
        static let collapsedWidth: CGFloat = 120
        static let expandedWidth: CGFloat = 420
        static let height: CGFloat = 120
        static let verticalOffset: CGFloat = 0
    }
    
    /// Animation timing
    enum Animation {
        static let expandDuration: TimeInterval = 0.2
        static let collapseDuration: TimeInterval = 0.15
        static let panelResizeDuration: TimeInterval = 0.3
        static let contentDelay: TimeInterval = 0.05
        static let animationCompleteDelay: TimeInterval = 0.35
        static let buttonPressAnimation: TimeInterval = 0.1
        static let hoverSpringResponse: Double = 0.3
        static let hoverSpringDamping: Double = 0.6
        static let contentScale: CGFloat = 0.95
    }
    
    /// View layout constants
    enum Layout {
        static let compactSpacing: CGFloat = 12
        static let expandedSpacing: CGFloat = 14
        static let controlButtonSpacing: CGFloat = 10
        static let equalizerBarSpacing: CGFloat = 3
        static let horizontalPaddingCompact: CGFloat = 16
        static let horizontalPaddingExpanded: CGFloat = 18
        static let verticalPaddingExpanded: CGFloat = 14
    }
    
    /// Album artwork sizes
    enum Artwork {
        static let compactSize: CGFloat = 48
        static let expandedSize: CGFloat = 60
        static let compactCornerRadius: CGFloat = 6
        static let expandedCornerRadius: CGFloat = 8
    }
    
    /// Control button dimensions
    enum ControlButton {
        static let standardSize: CGFloat = 28
        static let playPauseSize: CGFloat = 36
        static let iconSize: CGFloat = 14
        static let playPauseIconSize: CGFloat = 14
    }
    
    /// Equalizer animation
    enum Equalizer {
        static let barCount = 4
        static let barWidth: CGFloat = 3
        static let barCornerRadius: CGFloat = 1.5
        static let animationInterval: TimeInterval = 0.05
        static let phaseIncrement: Double = 0.1
        static let baseHeights: [CGFloat] = [6, 9, 12, 15]
        static let heightMultiplier: CGFloat = 8
    }
    
    /// Spotify integration
    enum Spotify {
        static let pollingInterval: TimeInterval = 1.0
        static let positionPollingInterval: TimeInterval = 0.5
        static let stateUpdateDelay: TimeInterval = 0.2
        static let dataSeparator = "||"
        static let playingState = "playing"
    }
    
    /// Monitoring intervals
    enum Monitoring {
        static let spotifyCheckInterval: TimeInterval = 3.0
        static let visibilityUpdateDelay: TimeInterval = 0.5
    }
    
    /// Colors
    enum Color {
        static let spotifyGreenRGB = (red: 0.113, green: 0.733, blue: 0.325)
        static let placeholderGray: CGFloat = 0.2
        static let buttonBackgroundHover: CGFloat = 0.3
        static let buttonBackgroundDefault: CGFloat = 0.25
        static let inactiveOpacity: CGFloat = 0.7
        static let defaultOpacity: CGFloat = 0.85
    }
    
    /// Typography
    enum Typography {
        static let trackNameSize: CGFloat = 15
        static let artistNameSize: CGFloat = 12
        static let trackNameWeight: Font.Weight = .semibold
        static let artistNameWeight: Font.Weight = .regular
    }
}

