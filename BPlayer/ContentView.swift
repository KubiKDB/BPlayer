import SwiftUI
import AVFoundation
import MobileCoreServices
import MediaPlayer

struct MusicPlayerView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentTrackIndex: Int = 0
    @State private var trackFiles: [String] = []
    @State private var nowPlaying: String = "No track loaded"
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var trackDuration: TimeInterval = 0
    @State private var directoryPath = ""
    @State private var is_shuffling = false
    
    var body: some View {
        VStack(spacing: 40) {
            List(trackFiles, id: \ .self) { track in
                Button(action: {
                    if let index = trackFiles.firstIndex(of: track) {
                        currentTrackIndex = index
                        playTrack(at: index)
                    }
                }) {
                    Text(track)
                        .foregroundColor(.white)
                }
            }.background(Color(.darkGray).edgesIgnoringSafeArea(.all))
            
            Text(nowPlaying)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.white)

            VStack(spacing: 10) {
                            Slider(value: $currentTime, in: 0...trackDuration, onEditingChanged: sliderEditingChanged)
                                .accentColor(.white)
                            HStack {
                                Text(formatTime(currentTime))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatTime(trackDuration))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()

            HStack(spacing: 60) {
                Spacer()
                Button(action: previousTapped) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: 40, height: 30)
                        .foregroundColor(.white)
                }

                Button(action: playPauseTapped) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }

                Button(action: nextTapped) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 40, height: 30)
                        .foregroundColor(.white)
                }
                Button(action: shuffleTapped) {
                    Image(systemName: "shuffle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(is_shuffling ? .blue : .white)
                }
                Spacer()
            }

            
        }
        .background(Color(.darkGray).edgesIgnoringSafeArea(.all))
        .onAppear{
            configureAudioSession()
            setupRemoteCommands()
            loadTracksFromDirectory()
            trackFiles.sort()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard let player = audioPlayer, player.isPlaying else { return }
            currentTime = player.currentTime
            checkForTrackEnd()
        }
    }
    
//    func listFilesInDirectory(directoryName: String) -> [String]{
//        guard let directoryURL = Bundle.main.url(forResource: directoryName, withExtension: nil) else {
//            print("Directory not found")
//            return []
//        }
//        
//        do {
//            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
//            
//            var list:[String] = []
//            for fileURL in fileURLs {
//                list.append(fileURL.lastPathComponent)
//            }
//            return list
//        } catch {
//            print("Error reading contents of directory: \(error)")
//            return []
//        }
//    }
    
    func listFilesInDirectory(directoryName: URL) -> [String]{
//        guard let directoryURL = Bundle.main.url(forResource: directoryName, withExtension: nil) else {
//            print("Directory not found")
//            return []
//        }
        
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
                print("Custom directory created at: \(customDirectory.path)")
            } catch {
                print("Error creating custom directory: \(error)")
            }
        }
        
        directoryPath = customDirectory.path()
        trackFiles = listFilesInDirectory(directoryName: customDirectory)

//        trackFiles = listFilesInDirectory(directoryName: "music_library")
        if trackFiles.isEmpty {
            nowPlaying = "No MP3 files found"
        }
    }
    
//    private func loadTracksFromDirectory() {
//        let fileManager = FileManager.default
//
//        directoryPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Music").path()
//        
//        
//
//        if !fileManager.fileExists(atPath: directoryPath) {
//            do {
//                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
//            } catch {
//                print("Error creating custom directory: \(error)")
//            }
//        }
//        
//        do {
//            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
//            trackFiles = files.filter { $0.hasSuffix(".mp3") }
//
//            if !trackFiles.isEmpty {
//                playTrack(at: currentTrackIndex)
//            } else {
//                nowPlaying = "No MP3 files found"
//            }
//        } catch {
//            nowPlaying = "Failed to load tracks: \(error.localizedDescription)"
//        }
//    }

    private func playTrack(at index: Int) {
        let trackName = trackFiles[index]

        //        let trackName = "music_library/"+trackFiles[index].replacing(".mp3", with: "")
//        let trackPath = Bundle.main.path(forResource: trackName, ofType: "mp3")!

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
            setupNowPlayingInfo()
        } catch {
            nowPlaying = "Error playing track: \(error.localizedDescription)"
        }
    }

    private func playPauseTapped() {
        guard let audioPlayer = audioPlayer else { return }

        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
        } else {
            audioPlayer.play()
            isPlaying = true
        }
    }

    private func nextTapped() {
        guard !trackFiles.isEmpty else { return }

        currentTrackIndex = (currentTrackIndex + 1) % trackFiles.count
        playTrack(at: currentTrackIndex)
    }

    private func previousTapped() {
        guard !trackFiles.isEmpty else { return }

        currentTrackIndex = (currentTrackIndex - 1 + trackFiles.count) % trackFiles.count
        playTrack(at: currentTrackIndex)
    }

    private func shuffleTapped() {
        guard !trackFiles.isEmpty else { return }
        
        is_shuffling = !is_shuffling
        
        if is_shuffling {
            trackFiles.shuffle()
        }else{
            trackFiles.sort()
        }
        
        currentTrackIndex = 0
//        currentTrackIndex = Int.random(in: 0..<trackFiles.count)
        playTrack(at: currentTrackIndex)
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
        if player.currentTime >= player.duration - 0.5{
            nextTapped()
        }
    }

    private func setupNowPlayingInfo() {
        guard let player = audioPlayer else { return }

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlaying,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
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
