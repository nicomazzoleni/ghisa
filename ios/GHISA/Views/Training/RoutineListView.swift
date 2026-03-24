import SwiftData
import SwiftUI

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: RoutineListViewModel

    var body: some View {
        Group {
            if viewModel.templates.isEmpty {
                emptyState
            } else {
                templateList
            }
        }
        .background(Theme.Background.base)
        .navigationTitle("My Routines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    routineForm(template: nil)
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.Accent.primary)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadTemplates()
        }
    }

    private var templateList: some View {
        List {
            ForEach(viewModel.templates) { template in
                NavigationLink {
                    routineForm(template: template)
                } label: {
                    templateRow(template)
                }
                .listRowBackground(Theme.Background.surface)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteTemplate(viewModel.templates[index])
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func templateRow(_ template: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(template.name)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Text.primary)

            let exerciseCount = template.exercises.count
            let totalSets = template.exercises.compactMap(\.targetSets).reduce(0, +)
            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") · \(totalSets) sets")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Text.tertiary)
            Text("No routines yet")
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(Theme.Text.primary)
            Text("Save a workout as a routine to quick-start future sessions")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                routineForm(template: nil)
            } label: {
                Text("Create Routine")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
    }

    @ViewBuilder
    private func routineForm(template: WorkoutTemplate?) -> some View {
        let service = WorkoutTemplateService(modelContext: modelContext)
        if let user = try? modelContext.fetch(FetchDescriptor<User>()).first {
            RoutineFormView(
                viewModel: RoutineFormViewModel(
                    templateService: service,
                    user: user,
                    template: template
                )
            )
        }
    }
}
