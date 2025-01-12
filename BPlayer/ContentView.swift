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
    @AppStorage("selectedPlaylist") private var selectedPlaylist: Int = 0
    
    @State private var playlists: [Playlist] = [
        Playlist(id: 0, name: "All songs"),
        Playlist(id: 1, name: "Favorite")
    ]
    
    

    struct Playlist: Identifiable, Hashable {
        let id:Int
        var name: String
        var songs: [Song] = []
    }
    
    struct Song: Comparable, Hashable {
        var trackName:String
        var trackAlbumCover:UIImage
        var backgroundPlayerArtwork: MPMediaItemArtwork? = nil
        var isFavourited:Bool = false

        init(trackName: String, trackAlbumCover: UIImage) {
            self.trackName = trackName
            self.trackAlbumCover = trackAlbumCover
            self.backgroundPlayerArtwork = MPMediaItemArtwork(boundsSize: trackAlbumCover.size) { _ in trackAlbumCover}
        }
        
        static func < (lhs: Song, rhs: Song) -> Bool {
                return lhs.trackName < rhs.trackName
        }
    }
    
    private func createID() -> Int{
        return playlists.count
    }
    
    private func createPlaylist() {
        //TODO: create playlists
        print("Created playlist")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack{
                Text(playlists[selectedPlaylist].name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                
                Spacer()

                PlaylistMenuView(
                        playlists: $playlists,
                        onSelectPlaylist: selectPlaylist,
                        createPlaylist: createPlaylist
                )
            }.padding(.bottom, 5)
            
            
            List(playlists[selectedPlaylist].songs, id: \.self) { song in
                if let index = playlists[selectedPlaylist].songs.firstIndex(of: song) {
                    SongRowView(
                        song: song,
                        isFavorite: song.isFavourited,
                        onFavoriteToggle: {
                            //TODO: potential bug
                            playlists[selectedPlaylist].songs[index].isFavourited.toggle()
                            UserDefaults.standard.set(song.isFavourited, forKey: song.trackName)
                        },
                        onSelect: {
                            isRepeating = false
                            currentTrackIndex = index
                            playTrack(at: index)
                        }
                    )
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
                    Slider(value: $currentTime, in: 0...trackDuration, onEditingChanged: slideTrackbar).accentColor(.white)
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
                
                PlaybackControlsView(
                        isPlaying: $isPlaying,
                        isShuffling: $isShuffling,
                        isRepeating: $isRepeating,
                        onPlayPause: playPauseTapped,
                        onNext: next,
                        onPrevious: previous,
                        onShuffle: shuffle,
                        onRepeat: repeatTapped
                )

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
            playlists[selectedPlaylist].songs.sort()
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
        let files = listFilesInDirectory(directoryName: customDirectory)
        for file in files {
            let is_favourited = UserDefaults.standard.bool(forKey: file)
            
            var song:Song = Song(trackName: file, trackAlbumCover: fetchAlbumArtwork(from: URL(filePath: (directoryPath as NSString).appendingPathComponent(file))))
            song.isFavourited = is_favourited
            
            playlists[0].songs.append(song)
            if song.isFavourited{
                playlists[1].songs.append(song)
            }
        }
        selectPlaylist(index: selectedPlaylist)
        
        if playlists[0].songs.isEmpty {
            nowPlaying = "No MP3 files found"
        }
    }
    
    private func selectPlaylist(index: Int){
        if index != selectedPlaylist {
            playlists[1].songs = []
            for song in playlists[0].songs {
                if song.isFavourited{
                    playlists[1].songs.append(song)
                }
            }
            isRepeating = false
            isShuffling = false
            isPlaying = false
            playlists[index].songs.sort()
            audioPlayer?.stop()
            trackDuration = 0
            currentTime = 0
            nowPlaying = "No track loaded"
                    
            selectedPlaylist = index
            setupNowPlayingInfo()
        }
    }

    private func playTrack(at index: Int) {
        let trackName = playlists[selectedPlaylist].songs[index].trackName

        let trackPath = (directoryPath as NSString).appendingPathComponent(trackName)

        do {
            audioPlayer?.stop()
            audioPlayer = nil
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
    
    private func findPlaylist(_name:String) -> Playlist?{
        for playlist in playlists {
            if playlist.name == _name {
                return playlist
            }
        }
        return nil
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
        isPlaying.toggle()
    }

    private func next() {
        guard !playlists[selectedPlaylist].songs.isEmpty else { return }

        isRepeating = false
        currentTrackIndex = (currentTrackIndex + 1) % playlists[selectedPlaylist].songs.count
        playTrack(at: currentTrackIndex)
    }
    
    private func nextOnEnd(){
        guard !playlists[selectedPlaylist].songs.isEmpty else { return }
        
        if !isRepeating {
            currentTrackIndex = (currentTrackIndex + 1) % playlists[selectedPlaylist].songs.count
        }
        playTrack(at: currentTrackIndex)
    }

    private func previous() {
        guard !playlists[selectedPlaylist].songs.isEmpty else { return }

        isRepeating = false
        currentTrackIndex = (currentTrackIndex - 1 + playlists[selectedPlaylist].songs.count) % playlists[selectedPlaylist].songs.count
        playTrack(at: currentTrackIndex)
    }

    private func shuffle() {
        guard !playlists[selectedPlaylist].songs.isEmpty else { return }
        
        isShuffling.toggle()
        isRepeating = false
        
        if isShuffling {
            playlists[selectedPlaylist].songs.shuffle()
        }else{
            playlists[selectedPlaylist].songs.sort()
        }
                
        currentTrackIndex = 0
        playTrack(at: currentTrackIndex)
    }
    
    private func repeatTapped() {
        isRepeating.toggle()
    }
    
    private func slideTrackbar(editing: Bool) {
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
            nextOnEnd()
        }
    }

    private func setupNowPlayingInfo() {
        guard let player = audioPlayer else { return }

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlaying,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyArtwork: playlists[selectedPlaylist].songs[currentTrackIndex].backgroundPlayerArtwork!
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
            self.next()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            self.previous()
            return .success
        }
    }
}

struct MusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MusicPlayerView()
    }
}
