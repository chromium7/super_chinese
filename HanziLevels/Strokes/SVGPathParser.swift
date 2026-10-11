import Foundation
import CoreGraphics

/// The bundle uses M/L/Q/C/Z. Both absolute and relative commands, repeated
/// arguments, commas, decimals and exponent notation follow SVG path semantics.
enum SVGPathParser {
    enum ParseError: Error { case invalidPath }

    static func point(_ point: CGPoint, canvasSide: CGFloat = 1024) -> CGPoint {
        let scale = canvasSide / 1024
        return CGPoint(x: point.x * scale, y: (900 - point.y) * scale)
    }

    static func parse(_ source: String, canvasSide: CGFloat = 1024) throws -> CGPath {
        guard canvasSide.isFinite, canvasSide > 0 else { throw ParseError.invalidPath }
        var scanner = Scanner(bytes: Array(source.utf8))
        let path = CGMutablePath()
        var current = CGPoint.zero
        var start = CGPoint.zero
        var command: UInt8?
        var hasMove = false
        var hasDrawing = false

        while !scanner.isAtEnd {
            if let next = scanner.command() { command = next }
            guard let active = command else { throw ParseError.invalidPath }
            let relative = active >= 97
            let upper = relative ? active - 32 : active
            if upper == 90 { // Z has no arguments; the next token must be a command.
                guard hasMove else { throw ParseError.invalidPath }
                path.closeSubpath()
                current = start
                command = nil
                continue
            }
            guard upper == 77 || hasMove else { throw ParseError.invalidPath }
            let origin = relative ? current : .zero
            func readPoint() throws -> CGPoint {
                let x = try scanner.number()
                let y = try scanner.number()
                let result = CGPoint(x: x + origin.x, y: y + origin.y)
                guard result.x.isFinite, result.y.isFinite else { throw ParseError.invalidPath }
                return result
            }
            switch upper {
            case 77:
                current = try readPoint()
                start = current
                path.move(to: point(current, canvasSide: canvasSide))
                hasMove = true
                command = relative ? 108 : 76 // Subsequent moveto pairs are lineto.
            case 76:
                current = try readPoint()
                path.addLine(to: point(current, canvasSide: canvasSide))
                hasDrawing = true
            case 81:
                let control = try readPoint()
                current = try readPoint()
                path.addQuadCurve(to: point(current, canvasSide: canvasSide),
                                  control: point(control, canvasSide: canvasSide))
                hasDrawing = true
            case 67:
                let first = try readPoint()
                let second = try readPoint()
                current = try readPoint()
                path.addCurve(to: point(current, canvasSide: canvasSide),
                              control1: point(first, canvasSide: canvasSide),
                              control2: point(second, canvasSide: canvasSide))
                hasDrawing = true
            default:
                throw ParseError.invalidPath
            }
        }
        guard hasDrawing, let immutable = path.copy() else { throw ParseError.invalidPath }
        return immutable
    }

    private struct Scanner {
        let bytes: [UInt8]
        var index = 0

        mutating func skipSeparators() {
            while index < bytes.count, [9, 10, 13, 32, 44].contains(bytes[index]) { index += 1 }
        }

        var isAtEnd: Bool {
            mutating get { skipSeparators(); return index == bytes.count }
        }

        mutating func command() -> UInt8? {
            skipSeparators()
            guard index < bytes.count else { return nil }
            let byte = bytes[index]
            guard (65...90).contains(byte) || (97...122).contains(byte) else { return nil }
            index += 1
            return byte
        }

        mutating func number() throws -> CGFloat {
            skipSeparators()
            let start = index
            if index < bytes.count, bytes[index] == 43 || bytes[index] == 45 { index += 1 }
            var digits = 0
            while index < bytes.count, (48...57).contains(bytes[index]) { index += 1; digits += 1 }
            if index < bytes.count, bytes[index] == 46 {
                index += 1
                while index < bytes.count, (48...57).contains(bytes[index]) { index += 1; digits += 1 }
            }
            guard digits > 0 else { throw ParseError.invalidPath }
            if index < bytes.count, bytes[index] == 69 || bytes[index] == 101 {
                index += 1
                if index < bytes.count, bytes[index] == 43 || bytes[index] == 45 { index += 1 }
                let exponentStart = index
                while index < bytes.count, (48...57).contains(bytes[index]) { index += 1 }
                guard index > exponentStart else { throw ParseError.invalidPath }
            }
            guard let value = Double(String(decoding: bytes[start..<index], as: UTF8.self)), value.isFinite else {
                throw ParseError.invalidPath
            }
            return CGFloat(value)
        }
    }
}
