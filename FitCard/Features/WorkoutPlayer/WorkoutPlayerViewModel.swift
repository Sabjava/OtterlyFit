import Foundation

@MainActor
@Observable
final class WorkoutPlayerViewModel {
    private let service: WorkoutPlayerService
    private let timerEngine: TimerEngine
    private let voicePrompts: VoicePromptService
    private var timerTask: Task<Void, Never>?
    private var phaseStartCountdown = 0

    let routine: Routine
    let routineName: String

    private(set) var elapsedSeconds = 0
    private(set) var activeSeconds = 0
    private(set) var restSeconds = 0
    private(set) var completedSets = 0
    private(set) var completedRepetitions = 0
    private(set) var sessionSnapshot: WorkoutSessionSnapshot?
    private(set) var state: WorkoutPlayerState = .idle
    private(set) var blocks: [WorkoutPlayerBlock] = []

    private var startTime: Date?
    private var exerciseStats: [Int: ExerciseSessionStats] = [:]

    init(routine: Routine) {
        service = WorkoutPlayerService()
        timerEngine = TimerEngine()
        voicePrompts = VoicePromptService()
        self.routine = routine
        routineName = routine.name
        service.load(routine: routine)
        syncFromService()
    }

    init(
        routine: Routine,
        service: WorkoutPlayerService,
        timerEngine: TimerEngine,
        voicePromptService: VoicePromptService
    ) {
        self.service = service
        self.timerEngine = timerEngine
        voicePrompts = voicePromptService
        self.routine = routine
        routineName = routine.name
        service.load(routine: routine)
        syncFromService()
    }

    var hasSession: Bool {
        startTime != nil
    }

    var canStart: Bool {
        if case .idle = state, !blocks.isEmpty { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }

    var isRunning: Bool {
        state.isActive && !isPaused
    }

    var currentBlock: WorkoutPlayerBlock? {
        guard let index = state.exerciseIndex, blocks.indices.contains(index) else { return nil }
        return blocks[index]
    }

    /// Rep counter within the current set (resets each set: 1…N).
    var currentRepDisplay: (current: Int, total: Int)? {
        guard let index = state.exerciseIndex,
              blocks.indices.contains(index) else {
            return nil
        }
        let block = blocks[index]

        if case .setStart = state {
            return (1, block.repetitions)
        }

        if case .resting(_, _, let rep, let kind, _) = state {
            switch kind {
            case .repRest:
                return (min(rep + 1, block.repetitions), block.repetitions)
            case .setRest:
                return (1, block.repetitions)
            case .exerciseRest:
                return nil
            }
        }

        guard let rep = state.repNumber else { return nil }
        return (rep, block.repetitions)
    }

    var timerStyle: WorkoutTimerStyle {
        state.timerStyle
    }

    var canNextSet: Bool {
        guard let index = state.exerciseIndex,
              let set = state.setNumber,
              blocks.indices.contains(index) else {
            return false
        }
        return set < blocks[index].sets
    }

    var canNextExercise: Bool {
        guard let index = state.exerciseIndex else { return false }
        return index + 1 < blocks.count
    }

    var isSetStart: Bool {
        if case .setStart = state { return true }
        return false
    }

    var isExerciseStart: Bool {
        if case .exerciseStart = state { return true }
        return false
    }

    var progress: WorkoutPlayerProgress {
        WorkoutPlayerProgress(
            overallFraction: overallProgress,
            phaseFraction: phaseProgress,
            elapsedSeconds: elapsedSeconds,
            completedSets: completedSets,
            completedRepetitions: completedRepetitions,
            currentExerciseIndex: state.exerciseIndex ?? blocks.count,
            totalExercises: blocks.count
        )
    }

    var overallProgress: Double {
        guard !blocks.isEmpty else { return 0 }
        if case .completed = state {
            return sessionSnapshot?.completionPercentage ?? sessionCompletionFraction()
        }

        guard let index = state.exerciseIndex else { return 0 }
        let blockFraction = blockProgress(at: index)
        return min(1, (Double(index) + blockFraction) / Double(blocks.count))
    }

    var phaseProgress: Double {
        guard phaseStartCountdown > 0, let countdown = state.countdownValue else { return 0 }
        return 1 - (Double(countdown) / Double(phaseStartCountdown))
    }

    var elapsedTimeText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startWorkout() {
        elapsedSeconds = 0
        activeSeconds = 0
        restSeconds = 0
        completedSets = 0
        completedRepetitions = 0
        sessionSnapshot = nil
        startTime = .now
        exerciseStats = Dictionary(uniqueKeysWithValues: blocks.indices.map { ($0, ExerciseSessionStats()) })
        service.start()
        syncFromService()
        capturePhaseStart(from: state)
        announceTransition(from: .idle, to: state)
        startTimerLoop()
    }

    func pause() {
        speakButton("Pause")
        service.pause()
        syncFromService()
    }

    func resume() {
        speakButton("Resume")
        service.resume()
        syncFromService()
        capturePhaseStart(from: state)
    }

    func nextSet() {
        speakButton("Next set")
        resumeIfPaused()

        let before = state
        service.nextSet()
        syncFromService()
        handleTransition(from: before, to: state)
        capturePhaseStart(from: state)
        announceTransition(from: before, to: state, interrupt: true)
    }

    func nextExercise() {
        resumeIfPaused()

        let before = state
        service.nextExercise()
        syncFromService()
        handleTransition(from: before, to: state)
        capturePhaseStart(from: state)
        announceTransition(from: before, to: state, interrupt: true)
    }

    func restComplete() {
        speakButton("End rest")

        resumeIfPaused()
        guard case .resting = state else { return }
        let before = state
        service.restComplete()
        syncFromService()
        handleTransition(from: before, to: state)
        capturePhaseStart(from: state)
        announceTransition(from: before, to: state)
    }

    func finish() {
        speakButton("Finish")
        resumeIfPaused()

        let before = state
        service.finish()
        syncFromService()
        handleTransition(from: before, to: state)
        stopTimerLoop()
        announceTransition(from: before, to: state, interrupt: true)
    }

    func cleanup() {
        stopTimerLoop()
        voicePrompts.stopSpeaking()
    }

    private func startTimerLoop() {
        stopTimerLoop()
        timerTask = Task {
            for await _ in timerEngine.interval() {
                guard !Task.isCancelled else { return }

                if case .paused = state {
                    continue
                }

                if case .completed = state {
                    return
                }

                if case .idle = state {
                    return
                }

                let before = state
                service.tick()
                syncFromService()
                elapsedSeconds += 1
                trackElapsedTime(for: state)
                handleTransition(from: before, to: state)
                capturePhaseStart(from: before, to: state)
                announceTransition(from: before, to: state)

                if case .completed = state {
                    return
                }
            }
        }
    }

    private func syncFromService() {
        state = service.state
        blocks = service.blocks
    }

    private func stopTimerLoop() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleTransition(from previous: WorkoutPlayerState, to current: WorkoutPlayerState) {
        switch (previous, current) {
        case let (.exercising(pIndex, pSet, pRep, _), .exercising(cIndex, cSet, cRep, _)):
            if pIndex == cIndex, cSet == pSet, cRep > pRep {
                completedRepetitions += 1
                incrementRepetition(for: cIndex)
            }
            if pIndex == cIndex, cSet > pSet {
                completedSets += 1
                incrementSet(for: cIndex)
            }
            if pIndex < cIndex {
                completedRepetitions += 1
                completedSets += 1
                incrementRepetition(for: pIndex)
                incrementSet(for: pIndex)
            }

        case (.exercising(let index, _, _, _), .resting):
            completedRepetitions += 1
            incrementRepetition(for: index)

        default:
            break
        }

        if case .completed = current {
            finalizeSession()
        }
    }

    private func incrementRepetition(for index: Int) {
        var stats = exerciseStats[index, default: ExerciseSessionStats()]
        stats.completedRepetitions += 1
        exerciseStats[index] = stats
    }

    private func incrementSet(for index: Int) {
        var stats = exerciseStats[index, default: ExerciseSessionStats()]
        stats.completedSets += 1
        exerciseStats[index] = stats
    }

    private func trackElapsedTime(for state: WorkoutPlayerState) {
        switch state {
        case .preparing:
            activeSeconds += 1

        case .exerciseStart(let index, _):
            activeSeconds += 1
            var stats = exerciseStats[index, default: ExerciseSessionStats()]
            stats.activeSeconds += 1
            exerciseStats[index] = stats

        case .setStart(let index, _, _):
            activeSeconds += 1
            var stats = exerciseStats[index, default: ExerciseSessionStats()]
            stats.activeSeconds += 1
            exerciseStats[index] = stats

        case .exercising(let index, _, _, _):
            activeSeconds += 1
            var stats = exerciseStats[index, default: ExerciseSessionStats()]
            stats.activeSeconds += 1
            exerciseStats[index] = stats

        case .resting(let index, _, _, _, _):
            restSeconds += 1
            var stats = exerciseStats[index, default: ExerciseSessionStats()]
            stats.restSeconds += 1
            exerciseStats[index] = stats

        default:
            break
        }
    }

    func buildSessionSnapshot() -> WorkoutSessionSnapshot? {
        if let sessionSnapshot {
            return sessionSnapshot
        }

        guard hasSession else { return nil }

        finalizeSession()
        return sessionSnapshot
    }

    private func finalizeSession() {
        let endTime = Date.now
        let exerciseSessionStats = blocks.indices.map { index in
            let stats = exerciseStats[index, default: ExerciseSessionStats()]
            return WorkoutExerciseSessionStats(
                blockIndex: index,
                exerciseName: blocks[index].exerciseName,
                completedSets: stats.completedSets,
                completedRepetitions: stats.completedRepetitions,
                activeSeconds: stats.activeSeconds,
                restSeconds: stats.restSeconds
            )
        }

        sessionSnapshot = WorkoutSessionSnapshot(
            routineName: routineName,
            startTime: startTime ?? endTime,
            endTime: endTime,
            elapsedSeconds: elapsedSeconds,
            activeSeconds: activeSeconds,
            restSeconds: restSeconds,
            completedSets: completedSets,
            completedRepetitions: completedRepetitions,
            completionPercentage: sessionCompletionFraction(),
            exerciseStats: exerciseSessionStats
        )
    }

    private func sessionCompletionFraction() -> Double {
        var totalPlanned = 0
        var totalCompleted = 0

        for (index, block) in blocks.enumerated() {
            let planned = max(block.sets * block.repetitions, 1)
            totalPlanned += planned
            let stats = exerciseStats[index, default: ExerciseSessionStats()]
            totalCompleted += min(planned, stats.completedRepetitions)
        }

        guard totalPlanned > 0 else { return 0 }
        return min(1, Double(totalCompleted) / Double(totalPlanned))
    }

    private func capturePhaseStart(from state: WorkoutPlayerState) {
        if let countdown = state.countdownValue {
            phaseStartCountdown = countdown
        }
    }

    private func capturePhaseStart(from previous: WorkoutPlayerState, to current: WorkoutPlayerState) {
        if phaseKey(previous) != phaseKey(current) {
            capturePhaseStart(from: current)
        }
    }

    private func phaseKey(_ state: WorkoutPlayerState) -> String {
        switch state {
        case .idle:
            "idle"
        case .preparing:
            "preparing"
        case .exerciseStart(let index, _):
            "exercise-\(index)"
        case .setStart(let index, let set, _):
            "setstart-\(index)-\(set)"
        case .exercising(let index, let set, let rep, _):
            "exercise-\(index)-\(set)-\(rep)"
        case .resting(let index, let set, let rep, let kind, _):
            "rest-\(index)-\(set)-\(rep)-\(kind)"
        case .paused(let snapshot):
            phaseKey(snapshot.state)
        case .completed:
            "completed"
        }
    }

    private func blockProgress(at index: Int) -> Double {
        guard blocks.indices.contains(index) else { return 0 }
        let block = blocks[index]
        let totalSteps = max(block.sets * block.repetitions, 1)

        switch state {
        case .exerciseStart:
            return 0
        case .setStart(_, let set, _):
            return min(1, Double((set - 1) * block.repetitions) / Double(totalSteps))
        default:
            break
        }

        guard let set = state.setNumber, let rep = state.repNumber else { return 0 }

        let completedInBlock = (set - 1) * block.repetitions + max(rep - 1, 0)

        switch state {
        case .exercising:
            return min(1, Double(completedInBlock + 1) / Double(totalSteps))
        case .resting:
            return min(1, Double(completedInBlock) / Double(totalSteps))
        default:
            return min(1, Double(completedInBlock) / Double(totalSteps))
        }
    }

    private func announceTransition(
        from previous: WorkoutPlayerState,
        to current: WorkoutPlayerState,
        interrupt: Bool = false
    ) {
        if case .paused = current { return }

        let isPreparingCountdown = {
            if case (.preparing, .preparing) = (previous, current) { return true }
            return false
        }()

        if phaseKey(previous) == phaseKey(current), !isPreparingCountdown {
            return
        }

        switch (previous, current) {
        case (.idle, .preparing(let count)):
            voicePrompts.speak("Get ready. \(VoicePromptService.spokenCount(count))", interrupt: true)

        case (.preparing, .preparing(let count)):
            voicePrompts.speak(VoicePromptService.spokenCount(count), interrupt: true)

        case (.preparing, .exerciseStart(let index, _)):
            voicePrompts.speak("Go! \(exerciseName(at: index))", interrupt: interrupt)

        case (.resting(_, _, _, .exerciseRest, _), .exerciseStart(let index, _)),
             (_, .exerciseStart(let index, _)) where previous.exerciseIndex != index:
            voicePrompts.speak("Next exercise. \(exerciseName(at: index))", interrupt: interrupt)

        case (.resting(_, _, _, let kind, _), .exercising(let index, _, let rep, _)):
            switch kind {
            case .exerciseRest:
                break
            case .repRest:
                voicePrompts.speak(VoicePromptService.spokenCount(rep + 1), interrupt: interrupt)
            case .setRest:
                break
            }

        case (.resting(_, _, _, .setRest, _), .setStart(_, let set, _)):
            voicePrompts.speak("Set \(VoicePromptService.spokenCount(set))", interrupt: interrupt)

        case (.setStart, .exercising(_, _, let rep, _)),
             (.exerciseStart, .exercising(_, _, let rep, _)):
            voicePrompts.speak(VoicePromptService.spokenCount(rep), interrupt: interrupt)

        case let (.exercising(pIndex, pSet, pRep, _), .exercising(cIndex, cSet, cRep, _)):
            if pIndex == cIndex, pSet == cSet, cRep > pRep {
                voicePrompts.speak(VoicePromptService.spokenCount(cRep), interrupt: interrupt)
            } else if pIndex == cIndex, cSet > pSet {
                voicePrompts.speak("Set \(VoicePromptService.spokenCount(cSet))", interrupt: interrupt)
            }

        case (.exercising, .resting),
             (.preparing, .resting):
            voicePrompts.speakSoftly("Rest")

        case (_, .completed):
            voicePrompts.speak("Workout complete. Great job!", interrupt: true)

        default:
            break
        }
    }

    private func exerciseName(at index: Int) -> String {
        guard blocks.indices.contains(index) else { return "Exercise" }
        return blocks[index].exerciseName
    }

    private func speakButton(_ label: String) {
        voicePrompts.speak(label, interrupt: true)
    }

    private func resumeIfPaused() {
        if case .paused = state {
            service.resume()
            syncFromService()
        }
    }
}
