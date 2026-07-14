import SwiftUI

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                Spacer()
                if routine.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var summary: String {
        let exerciseCount = routine.exercises.count
        let duration = RoutineDurationCalculator.formattedDuration(routine.estimatedDuration)
        let exerciseLabel = exerciseCount == 1 ? "exercise" : "exercises"
        return "\(exerciseCount) \(exerciseLabel) · \(duration)"
    }
}

struct CreateRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Routine Name", text: $name)
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List(exercises, id: \.id) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    ExerciseRowView(exercise: exercise)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RoutineBlockRowView: View {
    let block: RoutineExercise

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.exercise?.name ?? "Exercise")
                    .font(.headline)

                Text(configSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var configSummary: String {
        var parts = ["\(block.sets) sets", "\(block.repetitions) reps"]
        if block.secondsPerRep > 0 {
            parts.append("\(block.secondsPerRep)s/rep")
        }
        if block.restBetweenSets > 0 {
            parts.append("\(block.restBetweenSets)s rest")
        }
        return parts.joined(separator: " · ")
    }
}
