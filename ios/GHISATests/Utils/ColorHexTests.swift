@testable import GHISA
import SwiftUI
import Testing

struct ColorHexTests {
    @Test func hexWithHash() {
        let color = Color(hex: "#0A84FF")
        // Color was created without crashing — basic validation
        #expect(color != Color.clear)
    }

    @Test func hexWithoutHash() {
        let color = Color(hex: "0A84FF")
        #expect(color != Color.clear)
    }

    @Test func hexBlack() {
        let color = Color(hex: "#000000")
        // Should not crash and produce a valid color
        #expect(color == Color(hex: "000000"))
    }

    @Test func hexWithAlpha() {
        let color = Color(hex: "#0A84FF80")
        // 8-char hex with alpha — should not crash
        #expect(color != Color.clear)
    }
}
