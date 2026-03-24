import SwiftUI

struct ExerciseHistoryView: View {
    @State private var viewModel: ExerciseHistoryViewModel

    private let user: User

    init(exercise: Exercise, user: User, workoutService: WorkoutService) {
        self.user = user
        _viewModel = State(initialValue: ExerciseHistoryViewModel(
            exercise: exercise,
            workoutService: workoutService
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Complete a workout with this exercise to see your history here.")
                )
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        prSummaryCard
                        if viewModel.supportsE1RM, !viewModel.chartDataPoints.isEmpty {
                            ExerciseProgressChart(dataPoints: viewModel.chartDataPoints)
                        }
                        sessionCards
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .background(Theme.Background.base)
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadHistory(user: user)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - PR Summary

    @ViewBuilder
    private var prSummaryCard: some View {
        if !viewModel.currentPRs.isEmpty {
            CardView {
                HStack(spacing: Theme.Spacing.xl) {
                    if let weightPR = viewModel.currentPRs[.heaviestWeight] {
                        prStatItem(
                            value: formatNumber(weightPR.value),
                            label: "Best Weight"
                        )
                    }
                    if let e1rmPR = viewModel.currentPRs[.bestE1RM] {
                        prStatItem(
                            value: formatNumber(e1rmPR.value),
                            label: "Best e1RM"
                        )
                    }
                    if let repsPR = viewModel.currentPRs[.mostRepsAtWeight] {
                        prStatItem(
                            value: formatNumber(repsPR.value),
                            label: "Best Reps"
                        )
                    }
                    Spacer()
                }
            }
        }
    }

    private func prStatItem(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(Theme.Accent.primary)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)
        }
    }

    // MARK: - Sessions

    private var sessionCards: some View {
        let fields = (viewModel.exercise.fieldDefinitions)
            .filter(\.isActive)
            .sorted { $0.sortOrder < $1.sortOrder }

        return ForEach(viewModel.sessions) { session in
            ExerciseHistorySessionCard(session: session, activeFields: fields)
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ value: Float) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }
}
