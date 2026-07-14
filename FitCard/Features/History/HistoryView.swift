import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    var onClose: (() -> Void)?

    @State private var viewModel = HistoryViewModel()

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.workouts.isEmpty {
                ProgressView("Loading history…")
            } else if viewModel.workouts.isEmpty {
                ContentUnavailableView {
                    Label("No Workouts", systemImage: "clock")
                } description: {
                    Text(emptyStateMessage)
                } actions: {
                    if viewModel.selectedPeriod != .all {
                        Button("Show All Workouts") {
                            viewModel.selectedPeriod = .all
                        }
                    }
                }
            } else {
                List {
                    ForEach(viewModel.groupedSections) { section in
                        Section(section.title) {
                            ForEach(section.workouts, id: \.id) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutHistoryRowView(
                                        title: viewModel.workoutTitle(workout),
                                        timeText: viewModel.timeText(for: workout),
                                        durationText: viewModel.durationText(for: workout),
                                        completionText: viewModel.completionText(for: workout),
                                        isCompleted: workout.isCompleted
                                    )
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(workout, using: modelContext) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(onClose == nil ? .large : .inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onClose()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(HistoryPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .onAppear {
            Task { await viewModel.load(using: modelContext) }
        }
        .onChange(of: viewModel.selectedPeriod) {
            Task { await viewModel.load(using: modelContext) }
        }
        .refreshable {
            await viewModel.load(using: modelContext)
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.selectedPeriod {
        case .day:
            "No workouts recorded today. Try the All filter or complete a routine."
        case .week:
            "No workouts in the last 7 days. Try the All filter."
        case .month:
            "No workouts in the last month. Try the All filter."
        case .all:
            "Complete a workout to build your history."
        }
    }
}

private struct WorkoutHistoryRowView: View {
    let title: String
    let timeText: String
    let durationText: String
    let completionText: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(timeText, systemImage: "clock")
                    Label(durationText, systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(completionText)
                    .font(.subheadline.bold())
                    .foregroundStyle(isCompleted ? .green : .orange)

                Text(isCompleted ? "Complete" : "Partial")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(ModelContainer.preview)
}
