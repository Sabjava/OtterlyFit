import SwiftData
import SwiftUI
import UIKit

struct ExerciseConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ExerciseConfirmViewModel

    private let onFinished: () -> Void

    init(
        recognitionResult: RecognitionResult,
        existingExercise: Exercise?,
        onFinished: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: ExerciseConfirmViewModel(
                recognitionResult: recognitionResult,
                existingExercise: existingExercise
            )
        )
        self.onFinished = onFinished
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                if let image = UIImage(data: viewModel.recognitionResult.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                }
            }

            if viewModel.isExistingMatch {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Matched existing exercise")
                            Text("Confidence: \(Int(viewModel.confidence * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            } else {
                Section {
                    Label("New exercise will be created", systemImage: "plus.circle")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Exercise Details") {
                TextField("Name", text: $viewModel.name)

                Picker("Category", selection: $viewModel.category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }

                Picker("Difficulty", selection: $viewModel.difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue.capitalized).tag(difficulty)
                    }
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

            Section("Extracted Text") {
                Text(viewModel.recognitionResult.recognizedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Confirm Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    Task { await saveExercise() }
                } label: {
                    Text("Save Exercise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isSaving || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    onFinished()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.bar)
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            guard didSave else { return }
            onFinished()
            dismiss()
        }
    }

    private func saveExercise() async {
        let repository = ExerciseRepository(context: modelContext)
        await viewModel.save(using: repository, context: modelContext)
    }
}

#Preview {
    NavigationStack {
        ExerciseConfirmView(
            recognitionResult: RecognitionResult(
                kind: .new,
                suggestedName: "Push-Up",
                suggestedDescription: "Classic bodyweight exercise.",
                recognizedText: "Push-Up\nClassic bodyweight exercise.",
                imageData: Data(),
                confidence: 0
            ),
            existingExercise: nil
        )
    }
    .modelContainer(ModelContainer.preview)
}
