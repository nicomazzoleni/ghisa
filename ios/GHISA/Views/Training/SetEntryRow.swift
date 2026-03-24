import SwiftUI

struct SetEntryRow: View {
    let set: WorkoutSet
    let activeFields: [ExerciseFieldDefinition]
    let onUpdateValue: (WorkoutSetValue, Float?, String?, Bool?) -> Void
    let onDelete: () -> Void
    var onToggleSetFlags: (() -> Void)?
    var onUpdateNotes: ((String?) -> Void)?

    @State private var isEditingNote = false
    @State private var noteText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            setContent
            setFlagBadges
            setNotes
        }
        .onAppear {
            noteText = set.notes ?? ""
        }
    }

    @ViewBuilder
    private var setFlagBadges: some View {
        let flags = set.flagAssignments.map(\.flag)
        if !flags.isEmpty {
            FlagRow(flags: flags)
                .padding(.leading, 36)
                .padding(.bottom, Theme.Spacing.xs)
        }
    }

    @ViewBuilder
    private var setNotes: some View {
        if isEditingNote {
            HStack(spacing: Theme.Spacing.sm) {
                TextField("Set note...", text: $noteText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Text.secondary)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        commitNote()
                    }

                Button {
                    commitNote()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Accent.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 36)
            .padding(.bottom, Theme.Spacing.xs)
        } else if let notes = set.notes, !notes.isEmpty {
            Text(notes)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.secondary)
                .italic()
                .padding(.leading, 36)
                .padding(.bottom, Theme.Spacing.xs)
                .onTapGesture {
                    if onUpdateNotes != nil {
                        noteText = notes
                        isEditingNote = true
                    }
                }
        }
    }

    private func commitNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        onUpdateNotes?(trimmed.isEmpty ? nil : trimmed)
        isEditingNote = false
    }

    private var setContent: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("\(set.setNumber)")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.tertiary)
                .frame(width: 28)

            ForEach(activeFields) { field in
                if let value = valueFor(field: field) {
                    FieldValueInput(
                        fieldDefinition: field,
                        value: value,
                        onUpdate: { num, text, toggle in
                            onUpdateValue(value, num, text, toggle)
                        }
                    )
                }
            }

            Spacer(minLength: 0)

            if onUpdateNotes != nil {
                let hasNote = !(set.notes ?? "").isEmpty
                Button {
                    isEditingNote.toggle()
                    if isEditingNote {
                        noteText = set.notes ?? ""
                    }
                } label: {
                    Image(systemName: hasNote ? "note.text" : "note.text.badge.plus")
                        .font(.caption)
                        .foregroundStyle(hasNote ? Theme.Accent.primary : Theme.Text.tertiary)
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.body)
                    .foregroundStyle(Theme.Semantic.error.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .onLongPressGesture {
            onToggleSetFlags?()
        }
    }

    private func valueFor(field: ExerciseFieldDefinition) -> WorkoutSetValue? {
        set.values.first { $0.fieldDefinition.id == field.id }
    }
}
