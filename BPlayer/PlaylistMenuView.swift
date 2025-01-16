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
            Image(systemName: "line.3.horizontal")
                .resizable()
                .foregroundStyle(Color.blue)
                .frame(width: 25,height: 20) 
                .padding(.horizontal ,10)
//            Label("Playlists", systemImage: "line.3.horizontal")
//                .font(.headline)
//                .padding(.horizontal, 10)
        }
    }
}
