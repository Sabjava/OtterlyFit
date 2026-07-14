import SwiftUI

struct CountdownView: View {
    let value: Int
    var color: Color = .primary

    var body: some View {
        Text("\(value)")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(.easeInOut, value: value)
    }
}

#Preview {
    CountdownView(value: 3, color: .blue)
}
