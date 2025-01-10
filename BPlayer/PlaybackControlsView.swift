import SwiftUI

struct PlaybackControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var isShuffling: Bool
    @Binding var isRepeating: Bool

    var onPlayPause: () -> Void
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onShuffle: () -> Void
    var onRepeat: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button(action: onRepeat) {
                Image(systemName: "repeat")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isRepeating ? .blue : .white)
            }
            Spacer()
            Button(action: onPrevious) {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 36, height: 27)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(width: 36, height: 27)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: onShuffle) {
                Image(systemName: "shuffle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isShuffling ? .blue : .white)
            }
            Spacer()
        }
    }
}
