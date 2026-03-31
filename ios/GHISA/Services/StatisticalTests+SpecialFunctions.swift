// swiftlint:disable identifier_name
import Foundation

// MARK: - Special Mathematical Functions

extension StatisticalTests {
    /// Regularized upper incomplete gamma function Q(a, x) = 1 - P(a, x).
    /// Uses series expansion for small x, continued fraction for large x.
    static func regularizedUpperIncompleteGamma(a: Double, x: Double) -> Double {
        guard x >= 0, a > 0 else { return 1.0 }
        if x == 0 { return 1.0 }

        if x < a + 1 {
            return 1.0 - gammaSeriesP(a: a, x: x)
        } else {
            return gammaContinuedFractionQ(a: a, x: x)
        }
    }

    /// Regularized incomplete beta function I_x(a, b) via continued fraction (Lentz's method).
    static func regularizedIncompleteBeta(x: Double, a: Double, b: Double) -> Double {
        guard x > 0, x < 1 else {
            if x <= 0 { return 0.0 }
            return 1.0
        }

        let logBeta = lgamma(a) + lgamma(b) - lgamma(a + b)
        let front = exp(a * log(x) + b * log(1 - x) - logBeta)

        if x > (a + 1) / (a + b + 2) {
            return 1.0 - regularizedIncompleteBeta(x: 1 - x, a: b, b: a)
        }

        let maxIterations = 200
        let epsilon = 1e-14
        let tiny = 1e-30

        var c = 1.0
        var d = 1.0 - (a + b) * x / (a + 1)
        if abs(d) < tiny { d = tiny }
        d = 1.0 / d
        var result = d

        for m in 1 ... maxIterations {
            let md = Double(m)

            var numerator = md * (b - md) * x / ((a + 2 * md - 1) * (a + 2 * md))
            d = 1.0 + numerator * d
            if abs(d) < tiny { d = tiny }
            c = 1.0 + numerator / c
            if abs(c) < tiny { c = tiny }
            d = 1.0 / d
            result *= d * c

            numerator = -(a + md) * (a + b + md) * x / ((a + 2 * md) * (a + 2 * md + 1))
            d = 1.0 + numerator * d
            if abs(d) < tiny { d = tiny }
            c = 1.0 + numerator / c
            if abs(c) < tiny { c = tiny }
            d = 1.0 / d
            let delta = d * c
            result *= delta

            if abs(delta - 1.0) < epsilon { break }
        }

        return front * result / a
    }

    /// Series expansion for regularized lower incomplete gamma P(a, x).
    static func gammaSeriesP(a: Double, x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-14

        var sum = 1.0 / a
        var term = 1.0 / a

        for n in 1 ... maxIterations {
            term *= x / (a + Double(n))
            sum += term
            if abs(term) < abs(sum) * epsilon { break }
        }

        return sum * exp(-x + a * log(x) - lgamma(a))
    }

    /// Continued fraction for regularized upper incomplete gamma Q(a, x).
    static func gammaContinuedFractionQ(a: Double, x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-14
        let tiny = 1e-30

        var b0 = x + 1.0 - a
        var c = 1.0 / tiny
        var d = 1.0 / b0
        var result = d

        for iter in 1 ... maxIterations {
            let id = Double(iter)
            let an = id * (a - id)
            b0 += 2.0
            d = an * d + b0
            if abs(d) < tiny { d = tiny }
            c = b0 + an / c
            if abs(c) < tiny { c = tiny }
            d = 1.0 / d
            let delta = d * c
            result *= delta
            if abs(delta - 1.0) < epsilon { break }
        }

        return result * exp(-x + a * log(x) - lgamma(a))
    }
}

// swiftlint:enable identifier_name
