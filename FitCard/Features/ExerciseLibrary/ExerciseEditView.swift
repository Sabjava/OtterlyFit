import SwiftData
import SwiftUI

struct ExerciseEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ExerciseEditViewModel

    init(exercise: Exercise?) {
        _viewModel = State(initialValue: ExerciseEditViewModel(exercise: exercise))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section("Exercise Details") {
                TextField("Name", text: $viewModel.name)

                Picker("Category", selection: $viewModel.category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Text(ExerciseLibraryFormatting.label(for: category.rawValue)).tag(category)
                    }
                }

                Picker("Equipment", selection: $viewModel.equipment) {
                    ForEach(Equipment.allCases, id: \.self) { equipment in
                        Text(ExerciseLibraryFormatting.label(for: equipment.rawValue)).tag(equipment)
                    }
                }

                Picker("Difficulty", selection: $viewModel.difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(ExerciseLibraryFormatting.label(for: difficulty.rawValue)).tag(difficulty)
                    }
                }
            }

            Section("Muscle Groups") {
                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    Toggle(
                        ExerciseLibraryFormatting.label(for: muscle.rawValue),
                        isOn: Binding(
                            get: { viewModel.muscleGroups.contains(muscle) },
                            set: { isSelected in
                                if isSelected {
                                    if !viewModel.muscleGroups.contains(muscle) {
                                        viewModel.muscleGroups.append(muscle)
                                    }
                                } else {
                                    viewModel.muscleGroups.removeAll { $0 == muscle }
                                }
                            }
                        )
                    )
                }
            }

            Section("Description") {
                TextField("Description", text: $viewModel.exerciseDescription, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Instructions") {
                TextField("Instructions", text: $viewModel.instructions, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Tips") {
                TextField("Tips", text: $viewModel.tips, axis: .vertical)
                    .lineLimit(2...6)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Exercise" : "New Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(viewModel.isSaving || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func save() async {
        let didSave = await viewModel.save(using: modelContext)
        if didSave {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseEditView(exercise: nil)
    }
    .modelContainer(ModelContainer.preview)
}
