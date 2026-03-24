import SwiftData
import SwiftUI

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyLogViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                dailyLogContent(vm)
            } else {
                ProgressView()
                    .onAppear { setupViewModel() }
            }
        }
        .navigationTitle(viewModel?.formattedDate ?? "Daily Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dailyLogContent(_ vm: DailyLogViewModel) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                healthKitSection(vm)
                customFieldsSection(vm)
            }
            .padding(Theme.Spacing.lg)
        }
        .contentMargins(.bottom, 32, for: .scrollContent)
        .background(Theme.Background.base)
        .gesture(dateSwipeGesture(vm))
        .sheet(isPresented: Binding(
            get: { vm.showAddFieldSheet },
            set: { vm.showAddFieldSheet = $0 }
        )) {
            AddCustomFieldSheet { name, fieldType, unit in
                vm.addField(name: name, fieldType: fieldType, unit: unit)
            }
            .presentationDetents([.medium])
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear {
            Task { await vm.loadData() }
        }
        .onChange(of: vm.selectedDate) {
            Task { await vm.loadData() }
        }
    }

    @ViewBuilder
    private func healthKitSection(_ vm: DailyLogViewModel) -> some View {
        if !vm.healthKitAuthRequested {
            HealthKitOnboardingCard(isImporting: vm.isImportingHistory) {
                Task { await vm.requestHealthKitAccess() }
            }
        } else {
            HealthKitMetricGrid(data: vm.healthKitData, isLoading: vm.isLoadingHealthKit)
        }
    }

    private func customFieldsSection(_ vm: DailyLogViewModel) -> some View {
        CustomFieldsSection(
            fields: vm.customFields,
            currentValues: { vm.currentValue(for: $0) },
            onUpdate: { field, number, text, toggle in
                vm.updateFieldValue(field: field, numberValue: number, textValue: text, toggleValue: toggle)
            },
            onDelete: { vm.removeField($0) },
            onAddTapped: { vm.showAddFieldSheet = true }
        )
    }

    private func dateSwipeGesture(_ vm: DailyLogViewModel) -> some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { gesture in
                let horizontal = gesture.translation.width
                let vertical = gesture.translation.height
                guard abs(horizontal) > abs(vertical) else { return }
                if horizontal > 0 {
                    vm.goToPreviousDay()
                } else {
                    vm.goToNextDay()
                }
            }
    }

    private func setupViewModel() {
        guard let user = fetchUser() else { return }
        let dailyLogService = DailyLogService(modelContext: modelContext)
        let healthKitService = HealthKitService()
        let vm = DailyLogViewModel(
            dailyLogService: dailyLogService,
            healthKitService: healthKitService,
            user: user
        )
        viewModel = vm
    }

    private func fetchUser() -> User? {
        try? modelContext.fetch(FetchDescriptor<User>()).first
    }
}
