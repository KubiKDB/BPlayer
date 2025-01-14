import Foundation
import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    let onEditing: (Bool) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 5)
                    .cornerRadius(2.5)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 5)
                    .cornerRadius(2.5)

                Circle()
                    .fill(Color.white)
                    .frame(width: 15, height: 15)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let location = gesture.location.x
                                let newValue = Double(location / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                                onEditing(true)
                            }
                            .onEnded { _ in
                                onEditing(false)
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}
