import SwiftUI

struct PlaylistMenuView: View {
    @Binding var playlists: [MusicPlayerView.Playlist]
    var onSelectPlaylist: (Int) -> Void

    var body: some View {
        Menu {
            ForEach(playlists.indices, id: \.self) { index in
                Button(playlists[index].name) {
                    onSelectPlaylist(index)
                }
            }
        } label: {
            Label("Playlists", systemImage: "line.3.horizontal")
                .font(.headline)
                .padding(.horizontal, 10)
        }
    }
}
