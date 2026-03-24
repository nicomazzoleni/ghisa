import SwiftUI

enum Theme {
    // MARK: - Backgrounds

    enum Background {
        static let base = Color(hex: "#000000")
        static let surface = Color(hex: "#1C1C1E")
        static let elevated = Color(hex: "#2C2C2E")
        static let divider = Color(hex: "#38383A")
    }

    // MARK: - Accent

    enum Accent {
        static let primary = Color(hex: "#0A84FF")
        static let primaryDimmed = Color(hex: "#0A84FF").opacity(0.15)
    }

    // MARK: - Text

    enum Text {
        static let primary = Color.white
        static let secondary = Color(hex: "#ABABAB")
        static let tertiary = Color(hex: "#636366")
    }

    // MARK: - Semantic

    enum Semantic {
        static let success = Color(hex: "#30D158")
        static let warning = Color(hex: "#FFD60A")
        static let error = Color(hex: "#FF453A")
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 12
        static let input: CGFloat = 10
        static let barCorner: CGFloat = 4
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold)
        static let sectionHeader = Font.system(size: 20, weight: .semibold)
        static let cardTitle = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let callout = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 12, weight: .regular)
        static let metricValue = Font.system(size: 34, weight: .bold).monospacedDigit()
        static let metricUnit = Font.system(size: 15, weight: .regular)
    }

    // MARK: - Animation

    enum Animation {
        static let cardExpansion = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let contentAppear = SwiftUI.Animation.easeOut(duration: 0.25)
        static let chartInteraction = SwiftUI.Animation.easeOut(duration: 0.2)
    }

    // MARK: - Component Sizes

    enum Size {
        static let buttonMinHeight: CGFloat = 48
        static let tabBarIconWeight: Font.Weight = .medium
    }
}
