import SwiftUI

struct CustomFieldsSection: View {
    let fields: [DailyLogFieldDefinition]
    let currentValues: (DailyLogFieldDefinition) -> DailyLogValue?
    let onUpdate: (DailyLogFieldDefinition, Float?, String?, Bool?) -> Void
    let onDelete: (DailyLogFieldDefinition) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("My Fields")
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(Theme.Text.primary)

            if fields.isEmpty {
                emptyState
            } else {
                CardView {
                    VStack(spacing: 0) {
                        ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                            CustomFieldRow(
                                field: field,
                                value: currentValues(field)
                            ) { number, text, toggle in
                                onUpdate(field, number, text, toggle)
                            }

                            if index < fields.count - 1 {
                                Divider()
                                    .background(Theme.Background.divider)
                                    .padding(.vertical, Theme.Spacing.sm)
                            }
                        }
                    }
                }
            }

            addButton
        }
    }

    private var emptyState: some View {
        CardView {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Theme.Accent.primary)
                Text("Add your first custom field")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Text.secondary)
                Spacer()
            }
        }
        .onTapGesture { onAddTapped() }
    }

    private var addButton: some View {
        Button {
            onAddTapped()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("Add Field")
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Accent.primary)
        }
    }
}
