import SwiftData
import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: WorkoutSummaryViewModel
    @State private var showHistory = false

    init(routine: Routine, session: WorkoutSessionSnapshot) {
        _viewModel = State(initialValue: WorkoutSummaryViewModel(routine: routine, session: session))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statsGrid
                    exerciseSection
                }
                .padding()
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    saveStatusBar

                    if viewModel.didSave {
                        Button {
                            showHistory = true
                        } label: {
                            Label("View History", systemImage: "clock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.bar)
            }
            .sheet(isPresented: $showHistory) {
                NavigationStack {
                    HistoryView(onClose: { showHistory = false })
                }
            }
            .task {
                await viewModel.save(using: modelContext)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.session.routineName)
                .font(.title2.bold())

            Label(
                viewModel.session.completionPercentage >= 1.0 ? "Completed" : "Partial workout",
                systemImage: viewModel.session.completionPercentage >= 1.0 ? "checkmark.circle.fill" : "flag.checkered"
            )
            .font(.subheadline)
            .foregroundStyle(viewModel.session.completionPercentage >= 1.0 ? .green : .orange)

            Text("Started \(viewModel.startTimeText)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Ended \(viewModel.endTimeText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Duration", value: viewModel.durationText)
            statCard(title: "Completion", value: viewModel.completionText)
            statCard(title: "Active", value: viewModel.activeTimeText)
            statCard(title: "Rest", value: viewModel.restTimeText)
            statCard(title: "Sets", value: "\(viewModel.session.completedSets)")
            statCard(title: "Reps", value: "\(viewModel.session.completedRepetitions)")
            statCard(title: "Calories", value: viewModel.caloriesText)
            statCard(title: "Exercises", value: "\(viewModel.session.exerciseStats.count)")
        }
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)

            if viewModel.session.exerciseStats.isEmpty {
                Text("No exercise data recorded.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.session.exerciseStats) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stat.exerciseName)
                            .font(.subheadline.bold())

                        HStack {
                            summaryChip(title: "Sets", value: "\(stat.completedSets)")
                            summaryChip(title: "Reps", value: "\(stat.completedRepetitions)")
                            summaryChip(title: "Active", value: formatDuration(stat.activeSeconds))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    @ViewBuilder
    private var saveStatusBar: some View {
        Group {
            if viewModel.isSaving {
                Label("Saving workout…", systemImage: "arrow.clockwise")
            } else if viewModel.didSave {
                Label("Workout saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.bar)
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    WorkoutSummaryView(
        routine: Routine(name: "Morning Strength"),
        session: WorkoutSessionSnapshot(
            routineName: "Morning Strength",
            startTime: .now.addingTimeInterval(-900),
            endTime: .now,
            elapsedSeconds: 900,
            activeSeconds: 600,
            restSeconds: 300,
            completedSets: 6,
            completedRepetitions: 42,
            completionPercentage: 0.85,
            exerciseStats: [
                WorkoutExerciseSessionStats(
                    blockIndex: 0,
                    exerciseName: "Push-Up",
                    completedSets: 2,
                    completedRepetitions: 24,
                    activeSeconds: 200,
                    restSeconds: 90
                ),
            ]
        )
    )
    .modelContainer(ModelContainer.preview)
}
