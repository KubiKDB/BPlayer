import SwiftUI
import AVFoundation
import MobileCoreServices
import MediaPlayer

struct MusicPlayerView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentTrackIndex: Int = 0
    @State private var trackFiles: [String] = []
    @State private var trackImages: [UIImage] = []
    @State private var nowPlaying: String = "No track loaded"
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var trackDuration: TimeInterval = 0
    @State private var directoryPath = ""
    @State private var is_shuffling = false
    @State private var is_repeating = false
    @State private var backgroundPlayerArtwork: MPMediaItemArtwork? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            List(trackFiles, id: \ .self) { track in
                Button(action: {
                    if let index = trackFiles.firstIndex(of: track) {
                        is_repeating = false
                        currentTrackIndex = index
                        playTrack(at: index)
                    }
                }) {
                    HStack{
                        if let index = trackFiles.firstIndex(of: track) {
                            Image(uiImage: trackImages[index])
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                        Text(track.replacing(".mp3", with: ""))
                            .foregroundColor(.white)
                    }
                    
                }
            }
            .padding(.top, 1)
            
            
            VStack() {
                Spacer()
                
                Text(nowPlaying)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.white)
                
                Spacer()

                VStack(spacing: 8) {
                    Slider(value: $currentTime, in: 0...trackDuration, onEditingChanged: sliderEditingChanged).accentColor(.white)
                    HStack {
                        Text(formatTime(currentTime))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatTime(trackDuration))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()

                HStack(spacing: 0) {
                    Spacer()
                    Button(action: repeatTapped) {
                        Image(systemName: "repeat")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(is_repeating ? .blue : .white)
                    }
                    Spacer()
                    Button(action: previousTapped) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .frame(width: 36, height: 27)
                            .foregroundColor(.white)
                    }
                    Spacer()

                    Button(action: playPauseTapped) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.white)
                    }
                    Spacer()

                    Button(action: nextTapped) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .frame(width: 36, height: 27)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: shuffleTapped) {
                        Image(systemName: "shuffle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(is_shuffling ? .blue : .white)
                    }
                    Spacer()
                }
                Spacer()
            }
            .frame(height: 250)
            .background(Color(.darkGray))
        }
        .background(Color(.black)
        .edgesIgnoringSafeArea(.all))
        .onAppear{
            configureAudioSession()
            setupRemoteCommands()
            loadTracksFromDirectory()
            trackFiles.sort()
            for track in trackFiles {
                trackImages.append(fetchAlbumArtwork(from: URL(filePath: (directoryPath as NSString).appendingPathComponent(track))))
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard let player = audioPlayer, player.isPlaying else { return }
            currentTime = player.currentTime
            checkForTrackEnd()
        }
    }
    
    func listFilesInDirectory(directoryName: URL) -> [String]{
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryName, includingPropertiesForKeys: nil)
            
            var list:[String] = []
            for fileURL in fileURLs {
                list.append(fileURL.lastPathComponent)
            }
            return list
        } catch {
            print("Error reading contents of directory: \(error)")
            return []
        }
    }
    
    private func loadTracksFromDirectory(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let customDirectory = documentsURL.appendingPathComponent("Music")
                
        if !fileManager.fileExists(atPath: customDirectory.path) {
            do {
                try fileManager.createDirectory(at: customDirectory, withIntermediateDirectories: true, attributes: nil)
                print("Dir path: \(customDirectory.path)")
            } catch {
                print("Error creating custom directory: \(error)")
            }
        }
        
        directoryPath = customDirectory.path()
        trackFiles = listFilesInDirectory(directoryName: customDirectory)
        if trackFiles.isEmpty {
            nowPlaying = "No MP3 files found"
        }
    }

    private func playTrack(at index: Int) {
        let trackName = trackFiles[index]

        let trackPath = (directoryPath as NSString).appendingPathComponent(trackName)

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: trackPath))
            trackDuration = audioPlayer?.duration ?? 0
            currentTime = 0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            nowPlaying = trackName.replacing(".mp3", with: "")
            isPlaying = true
            
            let artwork = fetchAlbumArtwork(from: URL(filePath: (directoryPath as NSString).appendingPathComponent(trackFiles[currentTrackIndex])))
            backgroundPlayerArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork}
            setupNowPlayingInfo()
        } catch {
            nowPlaying = "Error playing track: \(error.localizedDescription)"
        }
    }
    
    //TODO: replace deprecation
    private func fetchAlbumArtwork(from url: URL) -> UIImage {
        let asset = AVAsset(url: url)
        let metadata = asset.commonMetadata
        let art:UIImage
        if let artworkItem = metadata.first(where: { $0.commonKey == .commonKeyArtwork }),
        let artworkData = artworkItem.dataValue,
        let image = UIImage(data: artworkData) {
            art = image
        }
        else {
            art = UIImage(named: "default_note")! // Fallback image
        }
        return art
    }
    
//    private func fetchAlbumArtwork(from url: URL) -> UIImage {
//        let asset = AVAsset(url: url)
//        let imageGenerator = AVAssetImageGenerator(asset: asset)
//        
//        var image: UIImage
//        do {
//            // Request a thumbnail at the first time index (0)
//            let thumbnailImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
//            image = UIImage(cgImage: thumbnailImage)
//        } catch {
//            // Fallback in case of an error
//            image = UIImage(named: "default_note")! // Default fallback image
//        }
//        
//        return image
//    }

    private func playPauseTapped() {
        guard let audioPlayer = audioPlayer else { return }

        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
        isPlaying = !isPlaying
    }

    private func nextTapped() {
        guard !trackFiles.isEmpty else { return }

        is_repeating = false
        currentTrackIndex = (currentTrackIndex + 1) % trackFiles.count
        playTrack(at: currentTrackIndex)
    }
    
    private func playNextOnEnd(){
        guard !trackFiles.isEmpty else { return }
        
        if !is_repeating {
            currentTrackIndex = (currentTrackIndex + 1) % trackFiles.count
        }
        playTrack(at: currentTrackIndex)
    }

    private func previousTapped() {
        guard !trackFiles.isEmpty else { return }

        is_repeating = false
        currentTrackIndex = (currentTrackIndex - 1 + trackFiles.count) % trackFiles.count
        playTrack(at: currentTrackIndex)
    }

    private func shuffleTapped() {
        guard !trackFiles.isEmpty else { return }
        
        is_shuffling = !is_shuffling
        is_repeating = false
        
        if is_shuffling {
            trackFiles.shuffle()
        }else{
            trackFiles.sort()
        }
        
        currentTrackIndex = 0
        playTrack(at: currentTrackIndex)
    }
    
    private func repeatTapped() {
        is_repeating = !is_repeating
    }
    
    private func sliderEditingChanged(editing: Bool) {
        if !editing, let player = audioPlayer {
            player.currentTime = currentTime
            setupNowPlayingInfo()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func checkForTrackEnd() {
        guard let player = audioPlayer else { return }
        if player.currentTime >= player.duration - 1{
            playNextOnEnd()
        }
    }

    private func setupNowPlayingInfo() {
        guard let player = audioPlayer else { return }
        
        

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlaying,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyArtwork: backgroundPlayerArtwork!
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            self.audioPlayer?.play()
            self.isPlaying = true
            self.setupNowPlayingInfo()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            self.audioPlayer?.pause()
            self.isPlaying = false
            self.setupNowPlayingInfo()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { _ in
            self.nextTapped()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            self.previousTapped()
            return .success
        }
    }
}

struct MusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MusicPlayerView()
    }
}
