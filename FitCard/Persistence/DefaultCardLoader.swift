import Foundation

enum DefaultCardLoader {
    static func imageData(named filename: String) -> Data? {
        let locations: [String?] = [
            "DefaultCards",
            "Resources/DefaultCards",
            nil,
        ]

        for subdirectory in locations {
            guard
                let url = Bundle.main.url(
                    forResource: filename,
                    withExtension: "jpg",
                    subdirectory: subdirectory
                ),
                let data = try? Data(contentsOf: url)
            else {
                continue
            }

            return data
        }

        return nil
    }
}
