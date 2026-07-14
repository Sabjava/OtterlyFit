import UIKit

enum SampleScanKind: String, CaseIterable, Identifiable {
    case pushUp = "Push-Up"
    case burpee = "Burpee"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .pushUp:
            "Tests matching an existing exercise"
        case .burpee:
            "Tests creating a new exercise"
        }
    }

    var lines: [String] {
        switch self {
        case .pushUp:
            [
                "Push-Up",
                "Classic bodyweight chest exercise.",
                "Keep your body in a straight line.",
                "Lower until chest nearly touches the floor.",
            ]
        case .burpee:
            [
                "Burpee",
                "Full-body cardio and strength movement.",
                "Drop to a plank, perform a push-up,",
                "jump feet forward and explode upward.",
            ]
        }
    }
}

enum SampleScanProvider {
    static func image(for kind: SampleScanKind) -> UIImage {
        let size = CGSize(width: 720, height: 480)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 72))

            let title = kind.rawValue as NSString
            title.draw(
                in: CGRect(x: 32, y: 16, width: size.width - 64, height: 44),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor.white,
                ]
            )

            var y: CGFloat = 104
            for (index, line) in kind.lines.dropFirst().enumerated() {
                let font = index == 0 ? UIFont.systemFont(ofSize: 24, weight: .semibold) : UIFont.systemFont(ofSize: 20)
                let text = line as NSString
                let rect = CGRect(x: 32, y: y, width: size.width - 64, height: 40)
                text.draw(in: rect, withAttributes: [
                    .font: font,
                    .foregroundColor: UIColor.black,
                ])
                y += index == 0 ? 44 : 36
            }

            let footer = "OtterlyFit Sample Card" as NSString
            footer.draw(
                in: CGRect(x: 32, y: size.height - 48, width: size.width - 64, height: 24),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.gray,
                ]
            )
        }
    }
}
