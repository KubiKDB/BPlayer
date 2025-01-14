import SwiftUI

struct SongRowView: View {
    let song: MusicPlayerView.Song
    var isFavorite: Bool
    var onFavoriteToggle: () -> Void
    var onSelect: () -> Void

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
    }
}
