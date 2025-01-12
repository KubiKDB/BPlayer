import SwiftUI

struct PlaylistMenuView: View {
    @Binding var playlists: [MusicPlayerView.Playlist]
    var onSelectPlaylist: (Int) -> Void
    var createPlaylist: () -> Void

    var body: some View {
        Menu {
            ForEach(playlists.indices, id: \.self) { index in
                Button(playlists[index].name) {
                    onSelectPlaylist(index)
                }
            }
            Button(action: createPlaylist) {
                Label("New Playlist", systemImage: "plus")
            }
        } label: {
            Label("Playlists", systemImage: "line.3.horizontal")
                .font(.headline)
                .padding(.horizontal, 10)
        }
    }
}
