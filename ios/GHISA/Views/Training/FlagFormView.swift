import SwiftUI

struct FlagFormView: View {
    let user: User
    let flagService: FlagService
    var existingFlag: Flag?
    var fixedScope: String?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedColor: String = "#0A84FF"
    @State private var selectedIcon: String?
    @State private var selectedScope: String = "workout"
    @State private var errorMessage: String?

    private var isEditing: Bool {
        existingFlag != nil
    }

    private static let colorPalette: [(name: String, hex: String)] = [
        ("Blue", "#0A84FF"),
        ("Green", "#30D158"),
        ("Red", "#FF453A"),
        ("Orange", "#FF9F0A"),
        ("Yellow", "#FFD60A"),
        ("Purple", "#BF5AF2"),
        ("Pink", "#FF375F"),
        ("Teal", "#64D2FF"),
        ("Indigo", "#5E5CE6"),
        ("Mint", "#63E6E2"),
    ]

    private static let iconOptions: [(name: String, symbol: String)] = [
        ("Fire", "flame.fill"),
        ("Star", "star.fill"),
        ("Bolt", "bolt.fill"),
        ("Arrow Up", "arrow.up.circle.fill"),
        ("Arrow Down", "arrow.down.circle.fill"),
        ("Heart", "heart.fill"),
        ("Flag", "flag.fill"),
        ("Trophy", "trophy.fill"),
        ("Clock", "clock.fill"),
        ("Dumbbell", "dumbbell.fill"),
        ("Repeat", "repeat"),
        ("Pause", "pause.circle.fill"),
        ("Exclamation", "exclamationmark.triangle.fill"),
        ("Checkmark", "checkmark.seal.fill"),
        ("Gauge", "gauge.high"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colorSection
                iconSection
                if !isEditing {
                    scopeSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Background.base)
            .navigationTitle(isEditing ? "Edit Flag" : "New Flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            .onAppear {
                if let flag = existingFlag {
                    name = flag.name
                    selectedColor = flag.color
                    selectedIcon = flag.icon
                    selectedScope = flag.scope
                } else if let fixedScope {
                    selectedScope = fixedScope
                }
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section("Name") {
            TextField("e.g. Deload, PR Attempt, Drop Set", text: $name)

            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Text("Preview:")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Text.tertiary)
                    FlagBadge(flag: previewFlag)
                }
            }
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                ForEach(Self.colorPalette, id: \.hex) { color in
                    Circle()
                        .fill(Color(hex: color.hex))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == color.hex {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2.5)
                            }
                        }
                        .onTapGesture { selectedColor = color.hex }
                        .accessibilityLabel(color.name)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Section("Icon (optional)") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                // No icon option
                Circle()
                    .fill(selectedIcon == nil ? Theme.Background.elevated : Theme.Background.surface)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text("—")
                            .font(.body)
                            .foregroundStyle(Theme.Text.secondary)
                    }
                    .overlay {
                        if selectedIcon == nil {
                            Circle()
                                .strokeBorder(Color(hex: selectedColor), lineWidth: 2)
                        }
                    }
                    .onTapGesture { selectedIcon = nil }

                ForEach(Self.iconOptions, id: \.symbol) { icon in
                    Circle()
                        .fill(selectedIcon == icon.symbol ? Theme.Background.elevated : Theme.Background.surface)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: icon.symbol)
                                .font(.body)
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                        .overlay {
                            if selectedIcon == icon.symbol {
                                Circle()
                                    .strokeBorder(Color(hex: selectedColor), lineWidth: 2)
                            }
                        }
                        .onTapGesture { selectedIcon = icon.symbol }
                        .accessibilityLabel(icon.name)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }

    // MARK: - Scope

    private var scopeSection: some View {
        Section("Scope") {
            if fixedScope != nil {
                Text(selectedScope.capitalized)
                    .foregroundStyle(Theme.Text.secondary)
            } else {
                Picker("Scope", selection: $selectedScope) {
                    Text("Workout").tag("workout")
                    Text("Exercise").tag("exercise")
                    Text("Set").tag("set")
                }
                .pickerStyle(.segmented)
            }

            Text(scopeDescription)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Text.tertiary)
        }
    }

    private var scopeDescription: String {
        switch selectedScope {
            case "workout":
                "Applied to the entire workout (e.g. Deload Week, Competition Prep)"
            case "exercise":
                "Applied to a specific exercise (e.g. PR Attempt, Warm-up)"
            case "set":
                "Applied to individual sets (e.g. Drop Set, Failure, Paused)"
            default:
                ""
        }
    }

    // MARK: - Preview Flag

    private var previewFlag: Flag {
        Flag(
            user: user,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor,
            icon: selectedIcon,
            scope: selectedScope
        )
    }

    // MARK: - Save

    private func save() {
        do {
            if let existing = existingFlag {
                try flagService.updateFlag(existing, name: name, color: selectedColor, icon: selectedIcon)
            } else {
                _ = try flagService.createFlag(
                    user: user,
                    name: name,
                    color: selectedColor,
                    icon: selectedIcon,
                    scope: selectedScope
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
