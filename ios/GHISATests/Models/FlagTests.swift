@testable import GHISA
import Testing

struct FlagTests {
    @Test func flagCreation() {
        let user = User()
        let flag = Flag(user: user, name: "Deload", color: "#FF0000", scope: "workout")
        #expect(flag.name == "Deload")
        #expect(flag.color == "#FF0000")
        #expect(flag.scope == "workout")
        #expect(flag.icon == nil)
        #expect(flag.assignments.isEmpty)
    }

    @Test func flagWithIcon() {
        let user = User()
        let flag = Flag(user: user, name: "PR Attempt", color: "#00FF00", icon: "star.fill", scope: "set")
        #expect(flag.icon == "star.fill")
        #expect(flag.scope == "set")
    }
}
