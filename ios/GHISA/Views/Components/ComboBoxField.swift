import SwiftUI

struct ComboBoxField: View {
    let label: String
    @Binding var text: String
    let suggestions: [String]
    var placeholder: String = ""

    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return suggestions }
        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(text) && $0 != text
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Text.secondary)

            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Text.primary)
                .padding(Theme.Spacing.md)
                .background(Theme.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in
                    showSuggestions = focused
                }
                .onChange(of: text) {
                    showSuggestions = isFocused
                }

            if showSuggestions, !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Button {
                            text = suggestion
                            showSuggestions = false
                            isFocused = false
                        } label: {
                            Text(suggestion)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Text.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                        }

                        if suggestion != filteredSuggestions.last {
                            Divider()
                                .background(Theme.Background.divider)
                        }
                    }
                }
                .background(Theme.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
            }
        }
    }
}
