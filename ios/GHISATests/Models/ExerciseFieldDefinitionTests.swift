@testable import GHISA
import Testing

struct ExerciseFieldDefinitionTests {
    @Test func fieldDefinitionDefaultValues() {
        let user = User()
        let exercise = Exercise(user: user, name: "Test")
        let field = ExerciseFieldDefinition(
            exercise: exercise,
            name: "Reps",
            fieldType: "number",
            systemKey: "reps",
            sortOrder: 0,
            isDefault: true
        )
        #expect(field.name == "Reps")
        #expect(field.fieldType == "number")
        #expect(field.unit == nil)
        #expect(field.systemKey == "reps")
        #expect(field.isActive == true)
        #expect(field.isDefault == true)
    }

    @Test func customFieldDefinition() {
        let user = User()
        let exercise = Exercise(user: user, name: "Test")
        let field = ExerciseFieldDefinition(
            exercise: exercise,
            name: "Grip Width",
            fieldType: "select",
            selectOptions: ["wide", "normal", "close"],
            sortOrder: 5
        )
        #expect(field.systemKey == nil)
        #expect(field.isDefault == false)
        #expect(field.selectOptions?.count == 3)
    }
}
