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
    @State var scrollText: Bool = false
    
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
        let hash_id: String
        var trackName:String
        var trackAlbumCover:UIImage?
        var backgroundPlayerArtwork: MPMediaItemArtwork?
        var isFavourited:Bool = false

        init(hash_id: String,trackName: String, trackAlbumCover: UIImage?) {
            self.hash_id = hash_id
            self.trackName = trackName
            self.trackAlbumCover = trackAlbumCover
            if trackAlbumCover != nil {
                self.backgroundPlayerArtwork = MPMediaItemArtwork(boundsSize: trackAlbumCover!.size) { _ in trackAlbumCover!}
            }
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
                            playlists[selectedPlaylist].songs[index].isFavourited.toggle()
                            UserDefaults.standard.set(playlists[selectedPlaylist].songs[index].isFavourited, forKey: song.hash_id)
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
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.white)
                
                VStack(spacing: 5) {
                    CustomSlider(value: $currentTime, range: 0...trackDuration, onEditing: slideTrackbar)
                        .padding(.horizontal, 5)
                    HStack {
                        Text(Helper.formatTime(currentTime))
                            .foregroundColor(.white)
                        Spacer()
                        Text(Helper.formatTime(trackDuration))
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
            Helper.configureAudioSession()
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
    
    private func loadTracksFromDirectory(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let customDirectory = documentsURL.appendingPathComponent("Music")
        if !fileManager.fileExists(atPath: customDirectory.path) {
            do {
                try fileManager.createDirectory(at: customDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating custom directory: \(error)")
            }
        }
        directoryPath = customDirectory.path()
        let files = Helper.listFilesInDirectory(directoryName: customDirectory)
        for file in files {
            let file_url = URL(filePath: (directoryPath as NSString).appendingPathComponent(file))
            
            let artwork = Helper.fetchAlbumArtwork(from: file_url)
            
            var song:Song = Song(hash_id: Helper.generateFileHash(fileURL: file_url),trackName: file, trackAlbumCover: artwork)
            song.isFavourited = UserDefaults.standard.bool(forKey: song.hash_id)
            
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
            currentTrackIndex = 0
            isRepeating = false
            isShuffling = false
            isPlaying = false
            playlists[index].songs.sort()
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            trackDuration = 0
            currentTime = 0
            nowPlaying = "No track loaded"
                    
            selectedPlaylist = index
            setupNowPlayingInfo(clear: true)
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

    private func playPauseTapped() {
        guard let audioPlayer = audioPlayer else { return }
        guard nowPlaying != "No track loaded" else { return }

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

    
    
    private func checkForTrackEnd() {
        guard let player = audioPlayer else { return }
        if player.currentTime >= player.duration - 1{
            nextOnEnd()
        }
    }

    private func setupNowPlayingInfo(clear: Bool = false) {
        guard let player = audioPlayer else { return }

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlaying,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyArtwork: playlists[selectedPlaylist].songs[currentTrackIndex].backgroundPlayerArtwork ?? MPMediaItemArtwork(boundsSize: UIImage(named: "AppIcon")!.size) { _ in UIImage(named: "AppIcon")!}
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = clear ? nil : nowPlayingInfo
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            self.playPauseTapped()
            self.setupNowPlayingInfo()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            self.playPauseTapped()
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
