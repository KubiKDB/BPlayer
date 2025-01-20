import SwiftUI

struct SearchView: View {
    @Binding var playlist: MusicPlayerView.Playlist
    @Binding var songs: [MusicPlayerView.Song]
    @State private var searchText = ""
    var playlist_id: Int
    var onSelect: (Int, MusicPlayerView.Song) -> Void
    
    var filteredSongs: [MusicPlayerView.Song] {
            if searchText.isEmpty {
                return songs
            } else {
                return songs.filter { $0.trackName.localizedCaseInsensitiveContains(searchText) }
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSongs.sorted(), id:\.self) { song in
                        if !playlist.songs.contains(song){
                            AddToPlaylistRow(
                                song: song,
                                onSelect: {onSelect(playlist_id, song)})
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search songs...")
            .navigationTitle("Songs")
        }
    }
}
