import SwiftUI

struct OtterlyFitLogoText: View {
    let text: String
    var fontSize: CGFloat = 60

    private static let fillColor = Color(red: 0x16 / 255, green: 0x5A / 255, blue: 0x75 / 255)
    private static let outlineOffsets: [CGSize] = {
        var offsets: [CGSize] = []
        for x in -2...2 {
            for y in -2...2 {
                guard x != 0 || y != 0 else { continue }
                if max(abs(x), abs(y)) <= 2 {
                    offsets.append(CGSize(width: x, height: y))
                }
            }
        }
        return offsets
    }()

    private var font: Font {
        .custom("Fredoka-Bold", size: fontSize)
    }

    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .foregroundStyle(Color.black.opacity(0.2))
                .offset(x: 4, y: 4)

            ZStack {
                ForEach(Array(Self.outlineOffsets.enumerated()), id: \.offset) { _, offset in
                    Text(text)
                        .font(font)
                        .foregroundStyle(.white)
                        .offset(x: offset.width, y: offset.height)
                }
            }

            Text(text)
                .font(font)
                .foregroundStyle(Self.fillColor)
        }
        .accessibilityLabel(text)
    }
}

#Preview {
    ZStack {
        Color.blue
        OtterlyFitLogoText(text: "OtterlyFit")
    }
}
