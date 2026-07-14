import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.2), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.65, tint: .orange)
        .frame(width: 120, height: 120)
        .padding()
}
