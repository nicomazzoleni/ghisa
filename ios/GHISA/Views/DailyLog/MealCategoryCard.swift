import SwiftUI

struct MealCategoryCard: View {
    let category: MealCategory
    let entries: [MealEntry]
    let nutrientDefinitions: [NutrientDefinition]
    let onAddTapped: () -> Void
    let onDelete: (MealEntry) -> Void
    let onEdit: (MealEntry) -> Void

    @State private var entryToDelete: MealEntry?

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                header
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
        }
        .alert("Delete Entry?", isPresented: Binding(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    onDelete(entry)
                }
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("Remove \(entryToDelete?.foodItem?.name ?? "this entry") from \(category.name)?")
        }
    }

    private var header: some View {
        HStack {
            Text(category.name)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Text.primary)

            if !entries.isEmpty {
                Text("(\(entries.count))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.tertiary)
            }

            Spacer()

            Button {
                onAddTapped()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Accent.primary)
            }
        }
    }

    private var emptyState: some View {
        Text("No entries yet")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Text.tertiary)
            .padding(.vertical, Theme.Spacing.xs)
    }

    private var entryList: some View {
        VStack(spacing: 0) {
            ForEach(entries, id: \.id) { entry in
                Button {
                    onEdit(entry)
                } label: {
                    MealEntryRow(entry: entry, nutrientDefinitions: nutrientDefinitions)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        entryToDelete = entry
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                if entry.id != entries.last?.id {
                    Divider()
                        .background(Theme.Background.divider)
                }
            }
        }
    }
}
