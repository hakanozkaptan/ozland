import SwiftUI

/// Dynamic Island style floating UI component
/// Displays currently playing Spotify track information in a floating pill-shaped interface
struct DynamicIslandView: View {
    // MARK: - Dependencies
    
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var panelManager: PanelManager
    @ObservedObject var appState: AppState
    
    // MARK: - State
    
    @State private var isHovered = false
    @State private var isAnimating = false
    @State private var currentHoverState = false
    @State private var showExpandedContent = false
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        _appState = ObservedObject(wrappedValue: appState)
    }

    var body: some View {
        ZStack {
            // Background with blur
            Capsule()
                .fill(.ultraThinMaterial)
            
            // Content
            ZStack {
                if showExpandedContent {
                    expandedContentView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: AppConstants.Animation.contentScale)),
                            removal: .opacity.combined(with: .scale(scale: AppConstants.Animation.contentScale))
                        ))
                } else {
                    compactContentView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: AppConstants.Animation.contentScale)),
                            removal: .opacity.combined(with: .scale(scale: AppConstants.Animation.contentScale))
                        ))
                }
            }
        }
        .frame(height: AppConstants.Panel.height)
        .contextMenu {
            Button(appState.language.localized(.minimize)) {
                panelManager.hide()
            }
        }
        .onTapGesture {
            toggleExpansion()
        }
        .onHover { hovering in
            // Only process if state actually changed and not animating
            guard hovering != currentHoverState, !isAnimating else { return }
            
            currentHoverState = hovering
            isHovered = hovering
            isAnimating = true
            
            if hovering {
                expandWithAnimation()
            } else {
                collapseWithAnimation()
            }
        }
    }
    
    // MARK: - Expansion Control
    
    private func toggleExpansion() {
        guard !isAnimating else { return }
        
        isAnimating = true
        let shouldExpand = !showExpandedContent
        
        if shouldExpand {
            expandWithAnimation()
        } else {
            collapseWithAnimation()
        }
    }
    
    private func expandWithAnimation() {
        withAnimation(.easeOut(duration: AppConstants.Animation.expandDuration)) {
            showExpandedContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.contentDelay) {
            panelManager.expand()
            self.completeAnimation()
        }
    }
    
    private func collapseWithAnimation() {
        withAnimation(.easeOut(duration: AppConstants.Animation.collapseDuration)) {
            showExpandedContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.contentDelay) {
            panelManager.collapse()
            self.completeAnimation()
        }
    }
    
    private func completeAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.animationCompleteDelay) {
            isAnimating = false
        }
    }
    
    // MARK: - Compact Content (Idle)
    
    private var compactContentView: some View {
        HStack(spacing: AppConstants.Layout.compactSpacing) {
            AlbumArtworkView(
                artworkImage: spotifyManager.artworkImage,
                size: AppConstants.Artwork.compactSize
            )
            
            EqualizerBarsView(isPlaying: spotifyManager.isPlaying)
        }
        .padding(.horizontal, AppConstants.Layout.horizontalPaddingCompact)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContentView: some View {
        HStack(spacing: AppConstants.Layout.expandedSpacing) {
            AlbumArtworkView(
                artworkImage: spotifyManager.artworkImage,
                size: AppConstants.Artwork.expandedSize
            )
            
            TrackInfoView(
                trackName: spotifyManager.trackName,
                artistName: spotifyManager.artistName
            )
            
            ControlButtonsView(spotifyManager: spotifyManager)
        }
        .padding(.horizontal, AppConstants.Layout.horizontalPaddingExpanded)
        .padding(.vertical, AppConstants.Layout.verticalPaddingExpanded)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Track Info View
    
    private struct TrackInfoView: View {
        let trackName: String
        let artistName: String
        
        private enum Constants {
            static let textAnimationDuration: TimeInterval = 0.3
            static let artistDelay: TimeInterval = 0.05
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(trackName)
                    .font(.system(
                        size: AppConstants.Typography.trackNameSize,
                        weight: AppConstants.Typography.trackNameWeight
                    ))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .animation(.easeInOut(duration: Constants.textAnimationDuration), value: trackName)
                
                Text(artistName)
                    .font(.system(
                        size: AppConstants.Typography.artistNameSize,
                        weight: AppConstants.Typography.artistNameWeight
                    ))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .animation(.easeInOut(duration: Constants.textAnimationDuration).delay(Constants.artistDelay), value: artistName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Control Buttons View
    
    private struct ControlButtonsView: View {
        @ObservedObject var spotifyManager: SpotifyManager
        
        var body: some View {
            HStack(spacing: AppConstants.Layout.controlButtonSpacing) {
                ControlButton(
                    icon: "shuffle",
                    isActive: spotifyManager.shuffleState,
                    action: { spotifyManager.toggleShuffle() }
                )
                
                ControlButton(
                    icon: "backward.fill",
                    isActive: false,
                    action: { spotifyManager.previousTrack() }
                )
                
                PlayPauseButton(
                    isPlaying: spotifyManager.isPlaying,
                    action: { spotifyManager.playPause() }
                )
                
                ControlButton(
                    icon: "forward.fill",
                    isActive: false,
                    action: { spotifyManager.nextTrack() }
                )
                
                ControlButton(
                    icon: spotifyManager.repeatState != "off" ? "repeat.1" : "repeat",
                    isActive: spotifyManager.repeatState != "off",
                    action: { spotifyManager.toggleRepeat() }
                )
            }
        }
    }
    
    // MARK: - Album Artwork Component
    
    private struct AlbumArtworkView: View {
        let artworkImage: NSImage?
        let size: CGFloat
        @State private var isHovered = false
        
        private enum Constants {
            static let hoverScale: CGFloat = 1.1
            static let defaultOpacity: CGFloat = 0.2
            static let hoverOpacity: CGFloat = 0.4
            static let defaultShadowRadius: CGFloat = 6
            static let hoverShadowRadius: CGFloat = 12
            static let defaultShadowY: CGFloat = 3
            static let hoverShadowY: CGFloat = 6
            static let springResponse: Double = AppConstants.Animation.hoverSpringResponse
            static let springDamping: Double = AppConstants.Animation.hoverSpringDamping
        }
        
        private var cornerRadius: CGFloat {
            size == AppConstants.Artwork.compactSize
                ? AppConstants.Artwork.compactCornerRadius
                : AppConstants.Artwork.expandedCornerRadius
        }
        
        init(artworkImage: NSImage?, size: CGFloat = AppConstants.Artwork.expandedSize) {
            self.artworkImage = artworkImage
            self.size = size
        }
        
        var body: some View {
            Group {
                if let artworkImage = artworkImage {
                    artworkImageView(artworkImage)
                } else {
                    placeholderView
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
        }
        
        private func artworkImageView(_ image: NSImage) -> some View {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .scaleEffect(isHovered ? Constants.hoverScale : 1.0)
                .shadow(
                    color: .black.opacity(isHovered ? Constants.hoverOpacity : Constants.defaultOpacity),
                    radius: isHovered ? Constants.hoverShadowRadius : Constants.defaultShadowRadius,
                    x: 0,
                    y: isHovered ? Constants.hoverShadowY : Constants.defaultShadowY
                )
                .animation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping), value: isHovered)
        }
        
        private var placeholderView: some View {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(white: AppConstants.Color.placeholderGray))
                .frame(width: size, height: size)
                .scaleEffect(isHovered ? Constants.hoverScale : 1.0)
                .animation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping), value: isHovered)
        }
    }
    
    // MARK: - Control Button Components
    
    private struct ControlButton: View {
        let icon: String
        let isActive: Bool
        let action: () -> Void
        @State private var isHovered = false
        @State private var isPressed = false
        
        private enum Constants {
            static let hoverScale: CGFloat = 1.15
            static let pressScale: CGFloat = 0.9
            static let hoverRotation: Double = 5
            static let activeOpacity: CGFloat = 1.0
            static let inactiveOpacity: CGFloat = AppConstants.Color.defaultOpacity
            static let inactiveForegroundOpacity = AppConstants.Color.inactiveOpacity
            static let springResponse: Double = AppConstants.Animation.hoverSpringResponse
            static let springDamping: Double = 0.5
            static let activeAnimationDuration: TimeInterval = 0.2
        }
        
        private var spotifyGreen: Color {
            Color(
                red: AppConstants.Color.spotifyGreenRGB.red,
                green: AppConstants.Color.spotifyGreenRGB.green,
                blue: AppConstants.Color.spotifyGreenRGB.blue
            )
        }
        
        var body: some View {
            Button(action: handleButtonPress) {
                Image(systemName: icon)
                    .font(.system(size: AppConstants.ControlButton.iconSize, weight: .medium))
                    .foregroundColor(isActive ? spotifyGreen : .white.opacity(Constants.inactiveForegroundOpacity))
                    .frame(width: AppConstants.ControlButton.standardSize, height: AppConstants.ControlButton.standardSize)
                    .scaleEffect(isPressed ? Constants.pressScale : (isHovered ? Constants.hoverScale : 1.0))
                    .opacity(isHovered ? Constants.activeOpacity : (isActive ? Constants.activeOpacity : Constants.inactiveOpacity))
                    .rotationEffect(.degrees(isHovered ? Constants.hoverRotation : 0))
            }
            .buttonStyle(.plain)
            .animation(.spring(response: Constants.springResponse, dampingFraction: AppConstants.Animation.hoverSpringDamping), value: isHovered)
            .animation(.easeInOut(duration: Constants.activeAnimationDuration), value: isActive)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        
        private func handleButtonPress() {
            withAnimation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.buttonPressAnimation) {
                withAnimation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping)) {
                    isPressed = false
                }
            }
            action()
        }
    }
    
    private struct PlayPauseButton: View {
        let isPlaying: Bool
        let action: () -> Void
        @State private var isHovered = false
        @State private var isPressed = false
        
        private enum Constants {
            static let hoverScale: CGFloat = 1.1
            static let pressScale: CGFloat = 0.95
            static let hoverRotation: Double = 5
            static let springResponse: Double = AppConstants.Animation.hoverSpringResponse
            static let springDamping: Double = 0.5
            static let stateAnimationDuration: TimeInterval = 0.2
        }
        
        var body: some View {
            Button(action: handleButtonPress) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: AppConstants.ControlButton.playPauseIconSize, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: AppConstants.ControlButton.playPauseSize, height: AppConstants.ControlButton.playPauseSize)
                    .background(Color(white: isHovered ? AppConstants.Color.buttonBackgroundHover : AppConstants.Color.buttonBackgroundDefault))
                    .clipShape(Circle())
                    .scaleEffect(isPressed ? Constants.pressScale : (isHovered ? Constants.hoverScale : 1.0))
                    .rotationEffect(.degrees(isHovered ? Constants.hoverRotation : 0))
            }
            .buttonStyle(.plain)
            .animation(.spring(response: Constants.springResponse, dampingFraction: AppConstants.Animation.hoverSpringDamping), value: isHovered)
            .animation(.easeInOut(duration: Constants.stateAnimationDuration), value: isPlaying)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        
        private func handleButtonPress() {
            withAnimation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Animation.buttonPressAnimation) {
                withAnimation(.spring(response: Constants.springResponse, dampingFraction: Constants.springDamping)) {
                    isPressed = false
                }
            }
            action()
        }
    }
}

// MARK: - Equalizer Bars View

/// Visual equalizer bars that animate when music is playing
struct EqualizerBarsView: View {
    let isPlaying: Bool
    @State private var animationPhase: Double = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(spacing: AppConstants.Layout.equalizerBarSpacing) {
            ForEach(0..<AppConstants.Equalizer.barCount, id: \.self) { index in
                EqualizerBar(
                    index: index,
                    isPlaying: isPlaying,
                    animationPhase: animationPhase
                )
            }
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        stopAnimation()
        guard isPlaying else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Equalizer.animationInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                animationPhase += AppConstants.Equalizer.phaseIncrement
                if animationPhase >= 2 * .pi {
                    animationPhase = 0
                }
            }
        }
        
        if let timer = animationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

/// Individual equalizer bar component
struct EqualizerBar: View {
    let index: Int
    let isPlaying: Bool
    let animationPhase: Double
    
    private enum Constants {
        static let colorPhaseMultiplier: Double = 0.8
        static let heightPhaseMultiplier: Double = 0.5
        static let inactiveOpacity: CGFloat = 0.8
        static let hueRange: ClosedRange<Double> = 0.1...0.9
        static let saturationRange: ClosedRange<Double> = 0.4...1.0
        static let brightnessRange: ClosedRange<Double> = 0.4...1.0
        static let animationDuration: TimeInterval = 0.1
    }
    
    private var baseHeight: CGFloat {
        guard index < AppConstants.Equalizer.baseHeights.count else {
            return AppConstants.Equalizer.baseHeights[0]
        }
        return AppConstants.Equalizer.baseHeights[index]
    }
    
    private var animatedColor: Color {
        guard isPlaying else {
            return .white.opacity(Constants.inactiveOpacity)
        }
        
        let colorPhase = animationPhase + Double(index) * Constants.colorPhaseMultiplier
        let hue = (sin(colorPhase) * 0.5 + 0.5) * (Constants.hueRange.upperBound - Constants.hueRange.lowerBound) + Constants.hueRange.lowerBound
        let saturation = 0.7 + sin(colorPhase * 2) * 0.3 // Oscillates within saturation range
        let brightness = 0.7 + sin(colorPhase * 1.5) * 0.3 // Oscillates within brightness range
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private var animatedHeight: CGFloat {
        guard isPlaying else { return baseHeight }
        let phase = animationPhase + Double(index) * Constants.heightPhaseMultiplier
        let wave = sin(phase) * 0.5 + 0.5
        return baseHeight + CGFloat(wave) * AppConstants.Equalizer.heightMultiplier
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: AppConstants.Equalizer.barCornerRadius)
            .fill(animatedColor)
            .frame(
                width: AppConstants.Equalizer.barWidth,
                height: isPlaying ? animatedHeight : baseHeight
            )
            .animation(.linear(duration: Constants.animationDuration), value: animationPhase)
    }
}

