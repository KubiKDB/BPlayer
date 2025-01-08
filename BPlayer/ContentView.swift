import SwiftUI
import AVFoundation
import MobileCoreServices
import MediaPlayer

struct MusicPlayerView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentTrackIndex: Int = 0
    @State private var nowPlaying: String = "No track loaded"
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var trackDuration: TimeInterval = 0
    @State private var directoryPath = ""
    @State private var isShuffling = false
    @State private var isRepeating = false
    @State private var backgroundPlayerArtwork: MPMediaItemArtwork? = nil
    @State private var selectedPlaylist: Playlist? = nil
    @State private var files: [String] = []
    @State private var pickFile: Bool = false
    
    @State private var playlists: [Playlist] = [
        Playlist(name: "All songs"),
        Playlist(name: "Favorite")
    ]
    
    @State private var songs: [Song] = []
    
    struct Playlist: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let songs: [Song] = []
    }
    
    struct Song: Comparable, Hashable {
        var trackName:String
        var trackAlbumCover:UIImage
        var backgroundPlayerArtwork: MPMediaItemArtwork? = nil
        var is_favourited:Bool = false

        init(trackName: String, trackAlbumCover: UIImage) {
            self.trackName = trackName
            self.trackAlbumCover = trackAlbumCover
            self.backgroundPlayerArtwork = MPMediaItemArtwork(boundsSize: trackAlbumCover.size) { _ in trackAlbumCover}
        }
        
        static func < (lhs: Song, rhs: Song) -> Bool {
                return lhs.trackName < rhs.trackName
        }
    }
    
//    struct DocumentPicker: UIViewControllerRepresentable {
//        var onPick: (URL?) -> Void
//
//        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
//            picker.delegate = context.coordinator
//            return picker
//        }
//
//        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//
//        func makeCoordinator() -> Coordinator {
//            Coordinator(onPick: onPick)
//        }
//
//        class Coordinator: NSObject, UIDocumentPickerDelegate {
//            var onPick: (URL?) -> Void
//
//            init(onPick: @escaping (URL?) -> Void) {
//                self.onPick = onPick
//            }
//
//            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//                onPick(urls.first)
//            }
//
//            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//                onPick(nil)
//            }
//        }
//    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack{
                Text(String(selectedPlaylist?.name ?? "All songs"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                Spacer()
//                Button("Select a File") {
//                        pickFile = true
//                    }
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
                Menu {
                    ForEach(playlists, id: \.self) { playlist in
                        Button(playlist.name) {
                            if let index = playlists.firstIndex(of: playlist) {
                                selectPlaylist(index: index)
                            }
                        }
                    }
                } label: {
                    Label("Playlists", systemImage: "line.3.horizontal")
                        .font(.headline)
                        .padding(.horizontal, 10)
                }
            }.padding(.bottom, 5)
            
            
            List(songs, id: \ .self) { song in
                Button(action: {
                    if let index = songs.firstIndex(of: song) {
                        isRepeating = false
                        currentTrackIndex = index
                        playTrack(at: index)
                    }
                }) {
                    HStack{
                        if let index = songs.firstIndex(of: song) {
                            Image(uiImage: songs[index].trackAlbumCover)
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text(song.trackName.replacing(".mp3", with: ""))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                //TODO favourite playlist
                                songs[index].is_favourited = !songs[index].is_favourited
                                // Save data
                                UserDefaults.standard.set(songs[index].is_favourited, forKey: songs[index].trackName)
                            }){
                                Image(systemName: songs[index].is_favourited ? "heart.fill" : "heart")
                                    .resizable()
                                    .foregroundColor(songs[index].is_favourited ? .red : .white)
                                    .frame(width: 20, height: 20)
                            }
                        }
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
                            .foregroundColor(isRepeating ? .blue : .white)
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
                            .foregroundColor(isShuffling ? .blue : .white)
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
            songs.sort()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard let player = audioPlayer, player.isPlaying else { return }
            currentTime = player.currentTime
            checkForTrackEnd()
        }
//        .sheet(isPresented: $pickFile) {
//                    DocumentPicker { url in
//                        if let url = url {
//                            importFile(from: url)
//                        }
//                    }
//                }
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
        files = listFilesInDirectory(directoryName: customDirectory)
        
        selectPlaylist(index: 0)
        
        if songs.isEmpty {
            nowPlaying = "No MP3 files found"
        }
    }
    
    private func selectPlaylist(index: Int){
        songs = []
        for file in files {
            // Retrieve data
            let is_favourited = UserDefaults.standard.bool(forKey: file)
            
            var song:Song = Song(trackName: file, trackAlbumCover: fetchAlbumArtwork(from: URL(filePath: (directoryPath as NSString).appendingPathComponent(file))))
            song.is_favourited = is_favourited
            if index == 0{
                songs.append(song)
            } else if index == 1 {
                if song.is_favourited{
                    songs.append(song)
                }
            }
        }
        isRepeating = false
        isShuffling = false
        isPlaying = false
        songs.sort()
        audioPlayer?.stop()
        trackDuration = 0
        currentTime = 0
        nowPlaying = "No track loaded"
        
        selectedPlaylist = playlists[index]
    }

    private func playTrack(at index: Int) {
        let trackName = songs[index].trackName

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
            backgroundPlayerArtwork = songs[index].backgroundPlayerArtwork
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
        guard !songs.isEmpty else { return }

        isRepeating = false
        currentTrackIndex = (currentTrackIndex + 1) % songs.count
        playTrack(at: currentTrackIndex)
    }
    
    private func playNextOnEnd(){
        guard !songs.isEmpty else { return }
        
        if !isRepeating {
            currentTrackIndex = (currentTrackIndex + 1) % songs.count
        }
        playTrack(at: currentTrackIndex)
    }

    private func previousTapped() {
        guard !songs.isEmpty else { return }

        isRepeating = false
        currentTrackIndex = (currentTrackIndex - 1 + songs.count) % songs.count
        playTrack(at: currentTrackIndex)
    }

    private func shuffleTapped() {
        guard !songs.isEmpty else { return }
        
        isShuffling = !isShuffling
        isRepeating = false
        
        if isShuffling {
            songs.shuffle()
        }else{
            songs.sort()
        }
                
        currentTrackIndex = 0
        playTrack(at: currentTrackIndex)
    }
    
    private func repeatTapped() {
        isRepeating = !isRepeating
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
    
//    private func importFile(from url: URL) {
//            let fileManager = FileManager.default
//            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//
//            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
//
//            do {
//                // If file already exists, delete it
//                if fileManager.fileExists(atPath: destinationURL.path) {
//                    try fileManager.removeItem(at: destinationURL)
//                }
//
//                // Copy file to the app's internal directory
//                try fileManager.copyItem(at: url, to: destinationURL)
//            } catch {
//                print("Error importing file: \(error)")
//            }
//        }
}

struct MusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MusicPlayerView()
    }
}
