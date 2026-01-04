import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.15)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "music.mic")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        Text("Now Playing")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 14)
                
                Divider()
                    .opacity(0.3)
                
                // Music Player Content
                NookView(spotifyManager: spotifyManager)
            }
        }
        .frame(width: 440, height: 580)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct NookView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @State private var isHoveringPlay = false
    @State private var isHoveringPrev = false
    @State private var isHoveringNext = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Album Art & Track Info
            VStack(spacing: 20) {
                // Album Art
                ZStack {
                    // Outer glow effect with pulse animation
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.4),
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                        .opacity(spotifyManager.isPlaying ? 0.8 : 0.6)
                        .scaleEffect(spotifyManager.isPlaying ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: spotifyManager.isPlaying)
                    
                    // Main album art
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.35),
                                    Color.blue.opacity(0.25),
                                    Color.purple.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 240, height: 240)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "music.note.tv.fill")
                                    .font(.system(size: 65, weight: .ultraLight))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.9),
                                                Color.blue.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                if spotifyManager.isPlaying {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                }
                            }
                        )
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                        .shadow(color: .green.opacity(0.2), radius: 30, x: 0, y: 0)
                }
                
                // Track Info
                VStack(spacing: 10) {
                    Text(spotifyManager.trackName)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(spotifyManager.artistName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                    
                    if !spotifyManager.albumName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "opticaldisc")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.7))
                            Text(spotifyManager.albumName)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 20)
            
            Divider()
                .opacity(0.3)
                .padding(.horizontal, 24)
            
            // Playback Controls
            VStack(spacing: 18) {
                // Main Controls
                HStack(spacing: 24) {
                    Button(action: { spotifyManager.previousTrack() }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isHoveringPrev ? Color.gray.opacity(0.18) : Color.gray.opacity(0.12),
                                        isHoveringPrev ? Color.gray.opacity(0.14) : Color.gray.opacity(0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(isHoveringPrev ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .help("Previous track")
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isHoveringPrev = hovering
                        }
                    }
                    
                    Button(action: { spotifyManager.playPause() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green,
                                            Color.green.opacity(0.85),
                                            Color.blue.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .scaleEffect(isHoveringPlay ? 1.1 : 1.0)
                            
                            Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: spotifyManager.isPlaying ? 0 : 2)
                        }
                        .shadow(color: .green.opacity(0.4), radius: isHoveringPlay ? 16 : 12, x: 0, y: isHoveringPlay ? 8 : 6)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .help(spotifyManager.isPlaying ? "Pause" : "Play")
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isHoveringPlay = hovering
                        }
                    }
                    
                    Button(action: { spotifyManager.nextTrack() }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isHoveringNext ? Color.gray.opacity(0.18) : Color.gray.opacity(0.12),
                                        isHoveringNext ? Color.gray.opacity(0.14) : Color.gray.opacity(0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .scaleEffect(isHoveringNext ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .help("Next track")
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isHoveringNext = hovering
                        }
                    }
                }
                .padding(.top, 18)
                
                // Spotify Badge
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                    }
                    
                    Text("Spotify")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
            }
            .padding(.bottom, 20)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

