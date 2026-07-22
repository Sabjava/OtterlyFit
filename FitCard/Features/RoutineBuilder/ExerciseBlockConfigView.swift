import SwiftData
import SwiftUI

struct ExerciseBlockConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var block: RoutineExercise
    let onSave: () -> Void

    @State private var weightText = ""

    var body: some View {
        Form {
            Section {
                Text(block.exercise?.name ?? "Exercise")
                    .font(.headline)
            }

            Section("Sets & Reps") {
                Stepper("Sets: \(block.sets)", value: $block.sets, in: 1...20)
                Stepper("Repetitions: \(block.repetitions)", value: $block.repetitions, in: 1...100)
            }

            Section("Timing") {
                Stepper("Seconds per rep: \(block.secondsPerRep)", value: $block.secondsPerRep, in: 1...120)
                Stepper("Rest between reps: \(block.restBetweenReps)s", value: $block.restBetweenReps, in: 0...120)
                Stepper("Rest between sets: \(block.restBetweenSets)s", value: $block.restBetweenSets, in: 0...300)
            }

            Section("Optional") {
                TextField("Weight (lb)", text: $weightText)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $block.notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                LabeledContent(
                    "Block Duration",
                    value: RoutineDurationCalculator.formattedDuration(
                        RoutineDurationCalculator.duration(for: block)
                    )
                )
            }
        }
        .navigationTitle("Configure Block")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    block.weight = Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines))
                    onSave()
                    dismiss()
                }
            }
        }
        .onAppear {
            if let weight = block.weight {
                weightText = String(weight)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseBlockConfigView(block: RoutineExercise(), onSave: {})
    }
    .modelContainer(ModelContainer.preview)
}
