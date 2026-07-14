import SwiftUI
import UIKit

struct ExerciseCardView: View {
    let title: String
    let imageData: Data?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding()
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ExerciseCardView(title: "Push-Up", imageData: nil)
        .padding()
}
