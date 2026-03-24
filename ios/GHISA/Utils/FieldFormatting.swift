import Foundation

func displayValue(for field: ExerciseFieldDefinition, in set: WorkoutSet) -> String {
    guard let value = set.values.first(where: { $0.fieldDefinition.id == field.id }) else {
        return "—"
    }

    switch field.fieldType {
        case "number":
            if let num = value.valueNumber {
                return num.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(num))"
                    : String(format: "%.1f", num)
            }
            return "—"
        case "text":
            return value.valueText ?? "—"
        case "toggle":
            if let toggle = value.valueToggle {
                return toggle ? "✓" : "✗"
            }
            return "—"
        case "dropdown":
            return value.valueText ?? "—"
        default:
            return "—"
    }
}
