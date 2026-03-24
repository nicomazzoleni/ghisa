import SwiftUI

struct HealthKitMetricGrid: View {
    let data: HealthKitDailyData?
    let isLoading: Bool

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
            HealthKitMetricCard(
                icon: "bed.double.fill",
                color: .purple,
                label: "Sleep",
                value: formatSleep(data?.sleepHours),
                unit: "hrs"
            )

            HealthKitMetricCard(
                icon: "figure.walk",
                color: .green,
                label: "Steps",
                value: formatInt(data?.steps),
                unit: ""
            )

            HealthKitMetricCard(
                icon: "heart.fill",
                color: .red,
                label: "Resting HR",
                value: formatInt(data?.restingHeartRate),
                unit: "bpm"
            )

            HealthKitMetricCard(
                icon: "waveform.path.ecg",
                color: .orange,
                label: "HRV",
                value: formatFloat(data?.hrv, decimals: 0),
                unit: "ms"
            )

            HealthKitMetricCard(
                icon: "flame.fill",
                color: Color(red: 1.0, green: 0.35, blue: 0.2),
                label: "Active Energy",
                value: formatFloat(data?.activeEnergyKcal, decimals: 0),
                unit: "kcal"
            )

            HealthKitMetricCard(
                icon: "figure.walk.motion",
                color: .teal,
                label: "Distance",
                value: formatFloat(data?.walkingDistanceKm, decimals: 1),
                unit: "km"
            )
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    // MARK: - Formatting

    private func formatSleep(_ hours: Float?) -> String {
        guard let hours else { return "—" }
        let wholeHours = Int(hours)
        let minutes = Int((hours - Float(wholeHours)) * 60)
        return "\(wholeHours)h \(minutes)m"
    }

    private func formatInt(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)"
    }

    private func formatFloat(_ value: Float?, decimals: Int) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(decimals)f", value)
    }
}
