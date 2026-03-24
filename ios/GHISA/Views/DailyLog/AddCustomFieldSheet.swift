import SwiftUI

struct AddCustomFieldSheet: View {
    let onAdd: (String, String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var fieldType = "number"
    @State private var unit = ""

    private let fieldTypes = ["number", "text", "toggle"]
    private let fieldTypeLabels = ["Number", "Text", "Toggle"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Field name", text: $name)
                }

                Section {
                    Picker("Type", selection: $fieldType) {
                        ForEach(Array(zip(fieldTypes, fieldTypeLabels)), id: \.0) { type, label in
                            Text(label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if fieldType == "number" {
                    Section {
                        TextField("Unit (optional)", text: $unit)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Background.base)
            .navigationTitle("New Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(name, fieldType, trimmedUnit.isEmpty ? nil : trimmedUnit)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
