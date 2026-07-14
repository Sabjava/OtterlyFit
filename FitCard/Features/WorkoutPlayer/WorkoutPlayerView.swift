import SwiftData
import SwiftUI

struct WorkoutPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let routine: Routine

    @State private var viewModel: WorkoutPlayerViewModel
    @State private var summarySession: WorkoutSessionSnapshot?

    init(routine: Routine) {
        self.routine = routine
        _viewModel = State(initialValue: WorkoutPlayerViewModel(routine: routine))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                statusHeader

                if let block = viewModel.currentBlock {
                    ExerciseCardView(title: block.exerciseName, imageData: block.cardImageData)
                        .padding(.horizontal)
                }

                progressSection
                timerSection
                countersSection
                Spacer()
                controlsSection
            }
            .padding(.vertical)
            .navigationTitle(viewModel.routineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        closeWorkout()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text(viewModel.elapsedTimeText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .fullScreenCover(item: $summarySession, onDismiss: { dismiss() }) { session in
            WorkoutSummaryView(routine: routine, session: session)
        }
        .task {
            if viewModel.canStart {
                viewModel.startWorkout()
            }
        }
    }

    private func closeWorkout() {
        if viewModel.hasSession {
            if !viewModel.isCompleted {
                viewModel.finish()
            }
            presentSummary()
        } else {
            dismiss()
        }
    }

    private func presentSummary() {
        guard let session = viewModel.buildSessionSnapshot() else {
            dismiss()
            return
        }
        summarySession = session
    }

    private var statusHeader: some View {
        Text(viewModel.state.statusTitle)
            .font(.title2.bold())
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        if viewModel.isPaused { return .yellow }
        switch viewModel.timerStyle {
        case .rest:
            return .green
        case .setStart:
            return .orange
        case .exerciseStart:
            return .red
        case .preparing, .reps:
            return .blue
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isRunning || viewModel.isCompleted {
            HStack(spacing: 20) {
                ProgressRingView(progress: viewModel.progress.overallFraction)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.progress.overallFraction * 100))%")
                        .font(.title3.bold())
                    Text("Exercise \(min(viewModel.progress.currentExerciseIndex + 1, viewModel.progress.totalExercises)) of \(viewModel.progress.totalExercises)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        if case .exerciseStart(let index, _) = viewModel.state {
            ZStack {
                ProgressRingView(progress: viewModel.phaseProgress, tint: .red)
                    .frame(width: 120, height: 120)
                Text(viewModel.blocks[index].exerciseName)
                    .font(.headline.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
            }
        } else if case .setStart(_, let set, _) = viewModel.state {
            ZStack {
                ProgressRingView(progress: viewModel.phaseProgress, tint: .orange)
                    .frame(width: 120, height: 120)
                VStack(spacing: 2) {
                    Text("Set")
                        .font(.caption.weight(.semibold))
                    Text("\(set)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.orange)
            }
        } else if case .exercising(_, _, let rep, _) = viewModel.state {
            ZStack {
                ProgressRingView(progress: viewModel.phaseProgress, tint: .blue)
                    .frame(width: 120, height: 120)
                CountdownView(value: rep, color: .blue)
            }
        } else if let countdown = viewModel.state.countdownValue {
            ZStack {
                ProgressRingView(progress: viewModel.phaseProgress, tint: viewModel.timerStyle.ringColor)
                    .frame(width: 120, height: 120)
                CountdownView(value: countdown, color: viewModel.timerStyle.ringColor)
            }
        } else if case .idle = viewModel.state {
            ProgressView("Starting workout…")
        } else if case .completed = viewModel.state {
            Label("Workout Complete", systemImage: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
        } else if case .paused = viewModel.state {
            Text("Workout paused")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var countersSection: some View {
        if let set = viewModel.state.setNumber,
           let block = viewModel.currentBlock,
           let repDisplay = viewModel.currentRepDisplay {
            HStack(spacing: 24) {
                counterCard(title: "Set", value: "\(set)/\(block.sets)", color: .primary)
                counterCard(title: "Rep", value: "\(repDisplay.current)/\(repDisplay.total)", color: .blue)
            }
            .padding(.horizontal)
        } else if case .exerciseStart = viewModel.state, let block = viewModel.currentBlock {
            HStack(spacing: 24) {
                counterCard(title: "Set", value: "1/\(block.sets)", color: .red)
                counterCard(title: "Rep", value: "1/\(block.repetitions)", color: .blue)
            }
            .padding(.horizontal)
        }
    }

    private func counterCard(title: String, value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var controlsSection: some View {
        VStack(spacing: 12) {
            if viewModel.blocks.isEmpty {
                Text("Add exercises to this routine before starting.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if viewModel.isCompleted {
                Button("View Summary") {
                    presentSummary()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    if viewModel.isPaused {
                        Button {
                            viewModel.resume()
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            viewModel.pause()
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if viewModel.canNextSet {
                    Button {
                        viewModel.nextSet()
                    } label: {
                        Label("Next Set", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.canNextExercise {
                    Button {
                        viewModel.nextExercise()
                    } label: {
                        Label("Next Exercise", systemImage: "forward.end.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if case .resting = viewModel.state {
                    Button {
                        viewModel.restComplete()
                    } label: {
                        Label("End Rest", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: .destructive) {
                    viewModel.finish()
                } label: {
                    Label("Finish Workout", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    WorkoutPlayerView(routine: Routine(name: "Morning Strength"))
        .modelContainer(ModelContainer.preview)
}
