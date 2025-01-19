import SwiftUI

struct PlaylistMenuView: View {
    @Binding var playlists: [MusicPlayerView.Playlist]
    var onSelectPlaylist: (Int) -> Void
    var createPlaylist: () -> Void
    let isAbleToCreate: Bool
    var deletePlaylist: (Int) -> Void

    var body: some View {
        Menu {
            ForEach(playlists.indices, id: \.self) { index in
                if isAbleToCreate || (index != 0 && index != 1) {
                    Button("\(playlists[index].name): \(playlists[index].songs.count)") {
                        onSelectPlaylist(index)
                    }
                }
            }
            if isAbleToCreate {
                Button(action: createPlaylist) {
                    Label("New Playlist", systemImage: "plus")
                }
            }
        } label: {
            Image(systemName: isAbleToCreate ? "line.3.horizontal" : "plus")
                .resizable()
                .foregroundStyle(Color.blue)
                .frame(width: isAbleToCreate ? 25 : 20,height: 20) 
                .padding(.horizontal ,10)
        }

    }
}
