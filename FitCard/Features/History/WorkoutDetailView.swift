import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var showDeleteConfirmation = false

    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                statsGrid
                exerciseSection
            }
            .padding()
        }
        .navigationTitle(workout.routine?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete this workout?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Workout", role: .destructive) {
                Task {
                    let repository = WorkoutRepository(context: modelContext)
                    try? await repository.delete(workout)
                    dismiss()
                }
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                workout.isCompleted ? "Completed" : "Partial workout",
                systemImage: workout.isCompleted ? "checkmark.circle.fill" : "flag.checkered"
            )
            .font(.subheadline)
            .foregroundStyle(workout.isCompleted ? .green : .orange)

            Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let endTime = workout.endTime {
                Text("Ended \(endTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Duration", value: formatDuration(workout.duration))
            statCard(title: "Completion", value: "\(Int(workout.completionPercentage * 100))%")
            statCard(title: "Active", value: formatDuration(workout.activeTime))
            statCard(title: "Rest", value: formatDuration(workout.restTime))
            statCard(title: "Calories", value: String(format: "%.0f kcal", workout.calories))
            statCard(title: "Exercises", value: "\(sortedExercises.count)")
        }
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)

            if sortedExercises.isEmpty {
                Text("No exercise details recorded.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedExercises, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.exercise?.name ?? "Exercise")
                            .font(.subheadline.bold())

                        HStack {
                            detailChip(title: "Sets", value: "\(entry.completedSets)")
                            detailChip(title: "Reps", value: "\(entry.completedRepetitions)")
                            detailChip(title: "Time", value: formatDuration(entry.actualDuration))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
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

    private func detailChip(title: String, value: String) -> some View {
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
    NavigationStack {
        WorkoutDetailView(workout: Workout(
            duration: 840,
            activeTime: 600,
            restTime: 240,
            calories: 85,
            isCompleted: true,
            completionPercentage: 1.0
        ))
    }
}
