import SwiftData
import SwiftUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = ExerciseListViewModel()
    @State private var showCreateExercise = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                ProgressView("Loading exercises…")
            } else if viewModel.exercises.isEmpty {
                ContentUnavailableView {
                    Label("No Exercises", systemImage: "figure.strengthtraining.traditional")
                } description: {
                    Text(emptyStateMessage)
                } actions: {
                    if viewModel.hasActiveFilters || !viewModel.searchQuery.isEmpty {
                        Button("Clear Filters") {
                            viewModel.searchQuery = ""
                            viewModel.clearFilters()
                            Task { await viewModel.load(using: modelContext) }
                        }
                    }

                    Button("Add Exercise") {
                        showCreateExercise = true
                    }
                }
            } else {
                List {
                    ForEach(viewModel.exercises, id: \.id) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(exercise, using: modelContext) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task { await viewModel.toggleFavorite(for: exercise, using: modelContext) }
                            } label: {
                                Label(
                                    exercise.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: exercise.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.yellow)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Exercises")
        .searchable(text: $viewModel.searchQuery, prompt: "Search by name")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            filterBar
        }
        .sheet(isPresented: $showCreateExercise) {
            NavigationStack {
                ExerciseEditView(exercise: nil)
            }
        }
        .task {
            await viewModel.load(using: modelContext)
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            Task { await viewModel.load(using: modelContext) }
        }
        .onChange(of: viewModel.selectedMuscle) { _, _ in
            Task { await viewModel.load(using: modelContext) }
        }
        .onChange(of: viewModel.selectedEquipment) { _, _ in
            Task { await viewModel.load(using: modelContext) }
        }
        .onChange(of: viewModel.favoritesOnly) { _, _ in
            Task { await viewModel.load(using: modelContext) }
        }
        .refreshable {
            await viewModel.load(using: modelContext)
        }
    }

    private var emptyStateMessage: String {
        if viewModel.hasActiveFilters || !viewModel.searchQuery.isEmpty {
            return "No exercises match your search or filters."
        }
        return "Scan a card or add an exercise to build your library."
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Favorites", isSelected: viewModel.favoritesOnly) {
                    viewModel.favoritesOnly.toggle()
                }

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    FilterChip(
                        title: ExerciseLibraryFormatting.label(for: muscle.rawValue),
                        isSelected: viewModel.selectedMuscle == muscle
                    ) {
                        viewModel.selectedMuscle = viewModel.selectedMuscle == muscle ? nil : muscle
                    }
                }

                ForEach(Equipment.allCases, id: \.self) { equipment in
                    FilterChip(
                        title: ExerciseLibraryFormatting.label(for: equipment.rawValue),
                        isSelected: viewModel.selectedEquipment == equipment
                    ) {
                        viewModel.selectedEquipment = viewModel.selectedEquipment == equipment ? nil : equipment
                    }
                }

                if viewModel.hasActiveFilters {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
    }
    .modelContainer(ModelContainer.preview)
}
