import Foundation
import AppKit

/// Manages Spotify integration via AppleScript
@MainActor
final class SpotifyManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var trackName: String = "No track found"
    @Published var artistName: String = "No artist found"
    @Published var albumName: String = ""
    @Published var isPlaying: Bool = false
    @Published var artworkImage: NSImage? = nil
    @Published var duration: Double = 0.0
    @Published var position: Double = 0.0
    @Published var shuffleState: Bool = false
    @Published var repeatState: String = "off" // "off", "track", "context"
    
    // MARK: - Private Properties
    
    nonisolated(unsafe) private var timer: Timer?
    nonisolated(unsafe) private var positionTimer: Timer?
    private var currentArtworkURL: String = ""

    private enum Constants {
        static let pollingInterval = AppConstants.Spotify.pollingInterval
        static let positionPollingInterval = AppConstants.Spotify.positionPollingInterval
        static let separator = AppConstants.Spotify.dataSeparator
        static let playingState = AppConstants.Spotify.playingState
        static let stateUpdateDelay = AppConstants.Spotify.stateUpdateDelay
    }
    
    private enum AppleScript {
        static let getTrackInfo = """
        tell application "Spotify"
            if it is running then
                try
                    set currentTrack to name of current track
                    set currentArtist to artist of current track
                    set currentAlbum to album of current track
                    set playerState to player state as string
                    set trackDuration to duration of current track
                    set playerPosition to player position
                    set trackId to id of current track
                    set artworkURL to artwork url of current track
                    set resultString to currentTrack & "||" & currentArtist & "||" & currentAlbum & "||" & playerState & "||" & (trackDuration as string) & "||" & (playerPosition as string)
                    set resultString to resultString & "||" & trackId & "||" & artworkURL
                    return resultString
                on error
                    return "ERROR||ERROR||ERROR||stopped||0||0||||"
                end try
            else
                return "NOT_RUNNING||NOT_RUNNING||NOT_RUNNING||stopped||0||0||||"
            end if
        end tell
        """

        static let getPosition = """
        tell application "Spotify"
            if it is running then
                try
                    return player position as string
                on error
                    return "0"
                end try
            else
                return "0"
            end if
        end tell
        """
        
        static func setPosition(_ position: Double) -> String {
            """
            tell application "Spotify"
                set player position to \(Int(position))
            end tell
            """
        }
        
        static let playPause = """
        tell application "Spotify"
            playpause
        end tell
        """
        
        static let nextTrack = """
        tell application "Spotify"
            next track
        end tell
        """
        
        static let previousTrack = """
        tell application "Spotify"
            previous track
        end tell
        """
        
        static let toggleShuffle = """
        tell application "Spotify"
            set shuffling to not shuffling
        end tell
        """
        
        static let toggleRepeat = """
        tell application "Spotify"
            set repeating to not repeating
        end tell
        """
        
        static let getShuffleState = """
        tell application "Spotify"
            if it is running then
                try
                    return shuffling as string
                on error
                    return "false"
                end try
            else
                return "false"
            end if
        end tell
        """
        
        static let getRepeatState = """
        tell application "Spotify"
            if it is running then
                try
                    return repeating as string
                on error
                    return "false"
                end try
            else
                return "false"
            end if
        end tell
        """
    }
    
    // MARK: - Lifecycle
    
    init() {
        startPolling()
    }
    
    deinit {
        stopPolling()
        stopPositionPolling()
    }
    
    // MARK: - Public Methods
    
    func playPause() {
        executeAppleScript(AppleScript.playPause)
    }
    
    func nextTrack() {
        executeAppleScript(AppleScript.nextTrack)
    }
    
    func previousTrack() {
        executeAppleScript(AppleScript.previousTrack)
    }
    
    func seek(to position: Double) {
        executeAppleScript(AppleScript.setPosition(position))
    }
    
    func toggleShuffle() {
        executeAppleScript(AppleScript.toggleShuffle)
        refreshStateAfterDelay { [weak self] in
            self?.updateShuffleState()
        }
    }
    
    func toggleRepeat() {
        executeAppleScript(AppleScript.toggleRepeat)
        refreshStateAfterDelay { [weak self] in
            self?.updateRepeatState()
        }
    }
    
    private func refreshStateAfterDelay(_ completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.stateUpdateDelay) {
            completion()
        }
    }
    
    // MARK: - Private Methods
    
    private func startPolling() {
        getCurrentTrack()
        updateShuffleState()
        updateRepeatState()

        timer = Timer.scheduledTimer(withTimeInterval: Constants.pollingInterval, repeats: true) { [weak self] _ in
            self?.getCurrentTrack()
            self?.updateShuffleState()
            self?.updateRepeatState()
        }

        startPositionPolling()
    }

    private func startPositionPolling() {
        positionTimer = Timer.scheduledTimer(withTimeInterval: Constants.positionPollingInterval, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }

    private func updatePosition() {
        guard let appleScript = NSAppleScript(source: AppleScript.getPosition) else { return }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        guard error == nil, let resultString = result.stringValue,
              let newPosition = Double(resultString) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.position = newPosition
        }
    }

    nonisolated private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    nonisolated private func stopPositionPolling() {
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    private func getCurrentTrack() {
        guard let appleScript = NSAppleScript(source: AppleScript.getTrackInfo) else { return }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        guard error == nil, let resultString = result.stringValue else {
            handleError()
            return
        }

        updateTrackInfo(from: resultString)
    }
    
    private func downloadArtwork(from urlString: String) {
        guard !urlString.isEmpty,
              urlString != currentArtworkURL,
              let url = URL(string: urlString) else { return }

        currentArtworkURL = urlString

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async {
                    self?.artworkImage = nil
                }
                return
            }

            DispatchQueue.main.async {
                self?.artworkImage = image
            }
        }.resume()
    }
    
    private func updateTrackInfo(from resultString: String) {
        let components = resultString.components(separatedBy: Constants.separator)

        guard components.count >= 8 else {
            DispatchQueue.main.async { [weak self] in
                self?.setErrorState()
            }
            return
        }

        let newTrackName = components[0]
        let newArtistName = components[1]
        let newAlbumName = components[2]
        let newIsPlaying = components[3] == Constants.playingState
        let newDuration = Double(components[4]) ?? 0.0
        let newPosition = Double(components[5]) ?? 0.0
        let artworkURL = components[7]

        // Download artwork if URL changed
        downloadArtwork(from: artworkURL)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.trackName != newTrackName {
                self.trackName = newTrackName
            }
            if self.artistName != newArtistName {
                self.artistName = newArtistName
            }
            if self.albumName != newAlbumName {
                self.albumName = newAlbumName
            }
            self.isPlaying = newIsPlaying
            self.duration = newDuration / 1000.0 // Convert from milliseconds to seconds
            self.position = newPosition
        }
    }
    
    private func handleError() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.trackName = "Spotify is not running"
            self.artistName = ""
            self.isPlaying = false
            self.artworkImage = nil
        }
    }
    
    private func setErrorState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.trackName = "No track found"
            self.artistName = ""
            self.isPlaying = false
            self.duration = 0.0
            self.position = 0.0
            self.artworkImage = nil
        }
    }
    
    private func executeAppleScript(_ script: String) {
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
    }
    
    private func updateShuffleState() {
        guard let appleScript = NSAppleScript(source: AppleScript.getShuffleState) else { return }
        
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        
        guard error == nil, let resultString = result.stringValue else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.shuffleState = resultString.lowercased() == "true"
        }
    }
    
    private func updateRepeatState() {
        guard let appleScript = NSAppleScript(source: AppleScript.getRepeatState) else { return }
        
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        
        guard error == nil, let resultString = result.stringValue else { return }
        
        DispatchQueue.main.async { [weak self] in
            // Spotify returns "true" or "false" for repeating
            // We'll use "off" for false and "context" for true (can be enhanced)
            self?.repeatState = resultString.lowercased() == "true" ? "context" : "off"
        }
    }
}
