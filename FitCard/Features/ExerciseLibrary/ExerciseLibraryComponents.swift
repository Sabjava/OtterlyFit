import SwiftUI

enum ExerciseLibraryFormatting {
    static func label(for value: String) -> String {
        value
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            exerciseThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if exercise.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let muscles = exercise.muscleGroups.map { ExerciseLibraryFormatting.label(for: $0.rawValue) }.joined(separator: ", ")
        let equipment = ExerciseLibraryFormatting.label(for: exercise.equipment.rawValue)
        if muscles.isEmpty { return equipment }
        return "\(muscles) · \(equipment)"
    }

    @ViewBuilder
    private var exerciseThumbnail: some View {
        if let data = exercise.cardImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
