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
    @AppStorage("nextPlaylistID") private var nextPlaylistID = 2
    @State var scrollText: Bool = false
    @State private var showPicker = false
    @State private var showAlert = false
    @State private var userInput: String = ""
    
    
    @State private var playlists: [Playlist] = [
        Playlist(id: 0, name: "All songs"),
        Playlist(id: 1, name: "Favorite")
    ]
    //["name":hash_id] for key "{playlist.id}"
    
    
    //Holds "Song" objects
    struct Playlist: Identifiable, Hashable {
        let id:Int
        var name: String
        var songs: [Song] = []
    }
    
    
    ///Contains name, image, favourited state and hash for saving information using UserDefaults
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
    
    private func savePlaylists(){
        for i in 2..<playlists.count {
            var list:[String] = []
            for song in playlists[0].songs {
                if playlists[i].songs.contains(song) {
                    list.append(song.hash_id)
                }
            }
            let out = [playlists[i].name : list]
            UserDefaults.standard.set(out, forKey: "\(playlists[i].id)")
            _ = 0
        }
    }
    
    private func createID() -> Int{
        let rv = nextPlaylistID
        nextPlaylistID += 1
        return rv
    }
    
    private func getInput(){
        showAlert = true
    }
    
    private func createPlaylist() {
        //TODO: save playlists
        for playlist in playlists {
            if playlist.name == userInput {
                userInput = ""
                print("This playlist already exists")
                return
            }
        }
        playlists.append(Playlist(id: createID(), name: userInput))
        userInput = ""
        savePlaylists()
    }
    
    private func addToPlaylist(index: Int, selectedSong: Int) {
        if !playlists[index].songs.contains(playlists[selectedPlaylist].songs[selectedSong]){
            playlists[index].songs.append(playlists[selectedPlaylist].songs[selectedSong])
            savePlaylists()
        }
        else {
            print("This song already added")
        }
    }
    
    private func removeFromPlaylist(index: Int){
        if selectedPlaylist == 1 {
            playlists[selectedPlaylist].songs[index].isFavourited.toggle()
            UserDefaults.standard.set(playlists[selectedPlaylist].songs[index].isFavourited, forKey: playlists[selectedPlaylist].songs[index].hash_id)
        } else {
            playlists[selectedPlaylist].songs.remove(at: index)
            savePlaylists()
        }
    }
    
    private func deletePlaylist(index: Int){
        if selectedPlaylist >= index {
            selectPlaylist(index: selectedPlaylist - 1)
        }
        playlists.remove(at: index)
        savePlaylists()
    }
    
    func deleteFile(index: Int) {
        let fileManager = FileManager.default

        let fileURL = URL(filePath: (directoryPath as NSString).appendingPathComponent(playlists[selectedPlaylist].songs[index].trackName))

            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    reloadSongs()
                    print("File deleted successfully.")
                } catch {
                    print("Error deleting file: \(error)")
                }
            } else {
                print("File does not exist.")
            }
    }

    
    
    var body: some View {
            VStack(spacing: 0) {
                HStack{
                    Spacer()
                    if selectedPlaylist < playlists.count {
                        Text(playlists[selectedPlaylist].name)
                            .font(.headline)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    Button(action: {
                         showPicker = true
                    }){
                        Image(systemName: "folder")
                            .resizable()
                            .foregroundStyle(Color.blue)
                            .frame(width: 25,height: 20)
                            .padding(.horizontal ,10)
                            
                    }
                    .sheet(isPresented: $showPicker) {
                        FilePicker { urls in
                            do {
                                try Helper.importFiles(from: urls, toDirectory: .documentDirectory, subdirectory: "Music")
                                DispatchQueue.main.async {
                                    reloadSongs()
                                    playlists[selectedPlaylist].songs.sort()
                                }
                                
                            }
                            catch {
                                print("Error importing file: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    PlaylistMenuView(
                        playlists: $playlists,
                        onSelectPlaylist: selectPlaylist,
                        createPlaylist: getInput,
                        isAbleToCreate: true,
                        deletePlaylist: deletePlaylist
                    )
                }
                .padding(.bottom, 5)
                
                if selectedPlaylist < playlists.count{
                    List(playlists[selectedPlaylist].songs, id: \.self) { song in
                        if let index = playlists[selectedPlaylist].songs.firstIndex(of: song) {
                            SongRowView(
                                playlists: $playlists,
                                id: index,
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
                                },
                                removeFromPlaylist: {
                                    removeFromPlaylist(index: index)
                                },
                                deleteSong: {
                                    deleteFile(index: index)
                                },
                                addToPlaylist: addToPlaylist
                            )
                        }
                    }
                    .background(Color(.black)
                        .edgesIgnoringSafeArea(.all))
                    .padding(.top, 1)
                    
                }
                
                VStack() {
                    
                    HStack {
                        Text(nowPlaying)
                            .font(.title2)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                            .padding()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                            .textInputAlert(
                            isPresented: $showAlert,
                            text: $userInput,
                            title: "Create Playlist",
                            message: "Enter playlist name:",
                            placeholder: "Playlist",
                            onSubmit: {
                                createPlaylist()
                            }
                            )
                        
                    }
                    .padding(.horizontal)
                    
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
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            }
            .padding(.horizontal,7)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2)
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
    
    private func reloadSongs(){
        playlists[0].songs = []
        playlists[1].songs = []
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
        playlists[selectedPlaylist].songs.sort()
    }
    
    ///Creates "Song" objects based on .mp3 files and puts them in "Playlist" objects
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
        for i in 2..<nextPlaylistID {
            let dict = UserDefaults.standard.dictionary(forKey: "\(i)") as? [String:[String]]
            guard let name = dict?.keys.first else {
                continue
            }
            var pl = Playlist(id: i, name: name)
            guard let songs = dict?[name] else {
                playlists.append(pl)
                continue
            }
            for song in playlists[0].songs {
                if songs.contains(song.hash_id){
                    pl.songs.append(song)
                }
            }
            playlists.append(pl)

        }
        selectPlaylist(index: selectedPlaylist)
        
        if playlists[0].songs.isEmpty {
//            nowPlaying = "No MP3 files found"
        }
    }
    
    ///Loads "Song" objects into current "Playlist" object
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
        var nowPlayingInfo: [String: Any] = [:]
        
        if !clear {
            nowPlayingInfo = [
                MPMediaItemPropertyTitle: nowPlaying,
                MPMediaItemPropertyPlaybackDuration: player.duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
                MPMediaItemPropertyArtwork: playlists[selectedPlaylist].songs[currentTrackIndex].backgroundPlayerArtwork ?? MPMediaItemArtwork(boundsSize: UIImage(named: "AppIcon")!.size) { _ in UIImage(named: "AppIcon")!}
            ]
        }
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
