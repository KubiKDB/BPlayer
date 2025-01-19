import SwiftUI

struct SongRowView: View {
    @Binding var playlists: [MusicPlayerView.Playlist]
    let id: Int
    let song: MusicPlayerView.Song
    var isFavorite: Bool
    var onFavoriteToggle: () -> Void
    var onSelect: () -> Void
    var removeFromPlaylist: () -> Void
    var deleteSong: () -> Void
    var addToPlaylist: (Int, Int) -> Void
    @State private var showDialog = false

    var body: some View {
        HStack {
            HStack{
                Image(uiImage: song.trackAlbumCover ?? UIImage(named: "default_note")!)
                    .resizable()
                    .frame(width: 30, height: 30)

                Text(song.trackName.replacingOccurrences(of: ".mp3", with: ""))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()

            }
            .frame(height: 30)
            .background(Color.white.opacity(0.0001))
            .onTapGesture(perform: onSelect)
    
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isFavorite ? .red : .white)
            }
        }
        .confirmationDialog("Choose an action", isPresented: $showDialog, titleVisibility: .visible) {
            Button("Delete") { deleteSong() }
            Button("Cancel", role: .cancel) { }
        }
        .contextMenu {
            Menu {
                ForEach(playlists.indices, id: \.self) { index in
                    if (index != 0 && index != 1) {
                        Button("\(playlists[index].name): \(playlists[index].songs.count)") {
                            addToPlaylist(index, id)
                        }
                    }
                }
            } label: {
                Label("Add to playlist", systemImage: "plus")
                    .foregroundColor(.white)
            }
            Button(action: removeFromPlaylist) {
                Label("Remove from playlist", systemImage: "minus")
            }
            Button(role: .destructive) {
                showDialog = true
            } label: {
                Label("Delete song", systemImage: "trash")
            }
            
        }
    }
}
