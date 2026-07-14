import SwiftData
import SwiftUI

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = RoutineListViewModel()
    @State private var showCreateSheet = false
    @State private var createdRoutine: Routine?
    @State private var routineToPlay: Routine?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.routines.isEmpty {
                ProgressView("Loading routines…")
            } else if viewModel.routines.isEmpty {
                ContentUnavailableView {
                    Label("No Routines", systemImage: "list.bullet")
                } description: {
                    Text("Create a routine and add exercises to build a guided workout.")
                } actions: {
                    Button("Create Routine") {
                        showCreateSheet = true
                    }
                }
            } else {
                List {
                    ForEach(viewModel.routines, id: \.id) { routine in
                        NavigationLink {
                            RoutineBuilderView(routine: routine)
                        } label: {
                            RoutineRowView(routine: routine)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                routineToPlay = routine
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            .tint(.green)
                            .disabled(routine.exercises.isEmpty)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(routine, using: modelContext) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task { await viewModel.toggleFavorite(routine, using: modelContext) }
                            } label: {
                                Label(
                                    routine.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: routine.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.yellow)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateRoutineSheet { name in
                Task {
                    createdRoutine = await viewModel.createRoutine(name: name, using: modelContext)
                }
            }
        }
        .navigationDestination(item: $createdRoutine) { routine in
            RoutineBuilderView(routine: routine)
        }
        .fullScreenCover(item: $routineToPlay) { routine in
            WorkoutPlayerView(routine: routine)
        }
        .task {
            await viewModel.load(using: modelContext)
        }
        .refreshable {
            await viewModel.load(using: modelContext)
        }
    }
}

extension Routine: Identifiable {}

#Preview {
    NavigationStack {
        RoutineListView()
    }
    .modelContainer(ModelContainer.preview)
}
