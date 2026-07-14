import SwiftData
import SwiftUI

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: RoutineBuilderViewModel
    @State private var showExercisePicker = false
    @State private var selectedBlock: RoutineExercise?
    @State private var showWorkoutPlayer = false

    init(routine: Routine) {
        _viewModel = State(initialValue: RoutineBuilderViewModel(routine: routine))
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Estimated Duration", value: viewModel.estimatedDurationText)
                LabeledContent("Exercises", value: "\(viewModel.blocks.count)")
            }

            Section("Exercise Blocks") {
                if viewModel.blocks.isEmpty {
                    Text("Add exercises to build this routine.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.blocks, id: \.id) { block in
                        Button {
                            selectedBlock = block
                        } label: {
                            RoutineBlockRowView(block: block)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.removeBlock(block, using: modelContext) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                Task { await viewModel.duplicateBlock(block, using: modelContext) }
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove { source, destination in
                        Task {
                            await viewModel.moveBlocks(
                                from: source,
                                to: destination,
                                using: modelContext
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showWorkoutPlayer = true
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .disabled(viewModel.blocks.isEmpty)
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showExercisePicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showWorkoutPlayer) {
            WorkoutPlayerView(routine: viewModel.routine)
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.blocks.isEmpty {
                Button {
                    showWorkoutPlayer = true
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.bar)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(exercises: viewModel.availableExercises) { exercise in
                Task { await viewModel.addExercise(exercise, using: modelContext) }
            }
        }
        .sheet(item: $selectedBlock) { block in
            NavigationStack {
                ExerciseBlockConfigView(block: block) {
                    Task { await viewModel.saveBlock(block, using: modelContext) }
                }
            }
        }
        .task {
            await viewModel.loadExercises(using: modelContext)
            viewModel.refreshEstimatedDuration(using: modelContext)
        }
    }
}

extension RoutineExercise: Identifiable {}

#Preview {
    NavigationStack {
        RoutineBuilderView(routine: Routine(name: "Morning Strength"))
    }
    .modelContainer(ModelContainer.preview)
}
