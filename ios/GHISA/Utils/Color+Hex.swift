import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let length = hex.count
        let r, g, b, a: Double

        switch length {
            case 6: // RRGGBB
                r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
                g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
                b = Double(rgbValue & 0x0000FF) / 255.0
                a = 1.0
            case 8: // RRGGBBAA
                r = Double((rgbValue & 0xFF00_0000) >> 24) / 255.0
                g = Double((rgbValue & 0x00FF_0000) >> 16) / 255.0
                b = Double((rgbValue & 0x0000_FF00) >> 8) / 255.0
                a = Double(rgbValue & 0x0000_00FF) / 255.0
            default:
                r = 0
                g = 0
                b = 0
                a = 1.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
