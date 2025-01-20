import SwiftUI

struct AddToPlaylistRow: View {
    let song: MusicPlayerView.Song
    var onSelect: () -> Void
    @State var selected: Bool = false

    var body: some View {
        HStack {
            Image(uiImage: song.trackAlbumCover ?? UIImage(named: "default_note")!)
                .resizable()
                .frame(width: 30, height: 30)
            Text(song.trackName.replacingOccurrences(of: ".mp3", with: ""))
                .foregroundColor(.white)
                .lineLimit(1)
                
            Spacer()
//            .onTapGesture(perform: onSelect)
    
            Button(action: selected ? {} : onSelect) {
                Image(systemName: selected ? "nosign" : "plus")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
            }
        }
    }
}
