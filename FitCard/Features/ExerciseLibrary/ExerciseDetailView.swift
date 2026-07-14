import SwiftData
import SwiftUI
import UIKit

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ExerciseDetailViewModel
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    init(exercise: Exercise) {
        _viewModel = State(initialValue: ExerciseDetailViewModel(exercise: exercise))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cardImageSection
                metadataSection

                if !viewModel.exercise.exerciseDescription.isEmpty {
                    detailSection(title: "Description", text: viewModel.exercise.exerciseDescription)
                }

                if !viewModel.exercise.instructions.isEmpty {
                    detailSection(title: "Instructions", text: viewModel.exercise.instructions)
                }

                if !viewModel.exercise.tips.isEmpty {
                    detailSection(title: "Tips", text: viewModel.exercise.tips)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleFavorite(using: modelContext) }
                } label: {
                    Image(systemName: viewModel.exercise.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(viewModel.exercise.isFavorite ? .yellow : .primary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Exercise", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                ExerciseEditView(exercise: viewModel.exercise)
            }
        }
        .confirmationDialog(
            "Delete this exercise?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Exercise", role: .destructive) {
                Task {
                    try? await viewModel.delete(using: modelContext)
                    dismiss()
                }
            }
        } message: {
            Text("This removes the exercise from your library. Routines that use it may be affected.")
        }
    }

    @ViewBuilder
    private var cardImageSection: some View {
        if let data = viewModel.exercise.cardImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            metadataRow(title: "Category", value: ExerciseLibraryFormatting.label(for: viewModel.exercise.category.rawValue))
            metadataRow(title: "Difficulty", value: ExerciseLibraryFormatting.label(for: viewModel.exercise.difficulty.rawValue))
            metadataRow(title: "Equipment", value: ExerciseLibraryFormatting.label(for: viewModel.exercise.equipment.rawValue))

            if !viewModel.exercise.muscleGroups.isEmpty {
                metadataRow(
                    title: "Muscle Groups",
                    value: viewModel.exercise.muscleGroups
                        .map { ExerciseLibraryFormatting.label(for: $0.rawValue) }
                        .joined(separator: ", ")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }

    private func detailSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(name: "Push-Up"))
    }
    .modelContainer(ModelContainer.preview)
}
