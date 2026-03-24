import SwiftData
import SwiftUI

struct FlagLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var user: User?
    @State private var flagService: FlagService?
    @State private var showingCreateFlag = false
    @State private var flagToEdit: Flag?
    @State private var errorMessage: String?
    @State private var refreshID = UUID()

    var body: some View {
        Group {
            if let user, let flagService {
                flagListContent(user: user, flagService: flagService)
            } else {
                ProgressView()
                    .onAppear { setup() }
            }
        }
        .navigationTitle("Flags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateFlag = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFlag) {
            refreshID = UUID()
        } content: {
            if let user, let flagService {
                FlagFormView(user: user, flagService: flagService)
            }
        }
        .sheet(item: $flagToEdit) { flag in
            if let user, let flagService {
                FlagFormView(user: user, flagService: flagService, existingFlag: flag)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func flagListContent(user: User, flagService: FlagService) -> some View {
        let workoutFlags = flagService.fetchFlags(for: user, scope: "workout")
        let exerciseFlags = flagService.fetchFlags(for: user, scope: "exercise")
        let setFlags = flagService.fetchFlags(for: user, scope: "set")
        let isEmpty = workoutFlags.isEmpty && exerciseFlags.isEmpty && setFlags.isEmpty

        return Group {
            if isEmpty {
                ContentUnavailableView(
                    "No Flags",
                    systemImage: "flag",
                    description: Text("Create flags to tag your workouts, exercises, and sets.")
                )
            } else {
                List {
                    flagSection("Workout", flags: workoutFlags, flagService: flagService)
                    flagSection("Exercise", flags: exerciseFlags, flagService: flagService)
                    flagSection("Set", flags: setFlags, flagService: flagService)
                }
                .scrollContentBackground(.hidden)
                .background(Theme.Background.base)
            }
        }
        .id(refreshID)
    }

    @ViewBuilder
    private func flagSection(_ title: String, flags: [Flag], flagService: FlagService) -> some View {
        if !flags.isEmpty {
            Section(title) {
                ForEach(flags, id: \.id) { flag in
                    Button {
                        flagToEdit = flag
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            FlagBadge(flag: flag)
                            Spacer()
                            Text("\(flag.assignments.count)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Text.tertiary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Text.tertiary)
                        }
                    }
                    .tint(Theme.Text.primary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteFlag(flag, flagService: flagService)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func deleteFlag(_ flag: Flag, flagService: FlagService) {
        do {
            try flagService.deleteFlag(flag)
            refreshID = UUID()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setup() {
        let fetchedUser = try? modelContext.fetch(FetchDescriptor<User>()).first
        guard let fetchedUser else { return }
        user = fetchedUser
        flagService = FlagService(modelContext: modelContext)
    }
}
