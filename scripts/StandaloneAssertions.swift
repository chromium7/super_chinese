// Limited assertion adapter for the CLT gate. This is deliberately not XCTest.
import Foundation

class XCTestCase {}

struct VerificationResources {
    let resourceURL: URL? = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
}

enum VerificationChecks {
    static var failures = 0
    static func fail(_ message: String, file: StaticString, line: UInt) {
        failures += 1
        print("FAIL \(file):\(line): \(message)")
    }
}

func XCTFail(_ message: String = "Failure", file: StaticString = #filePath, line: UInt = #line) {
    VerificationChecks.fail(message, file: file, line: line)
}

func XCTAssertTrue(_ value: @autoclosure () throws -> Bool, _ message: String = "",
                   file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try !value() { XCTFail("Expected true. \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertFalse(_ value: @autoclosure () throws -> Bool, _ message: String = "",
                    file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try !value(), message, file: file, line: line)
}

func XCTAssertEqual<T: Equatable>(_ lhs: @autoclosure () throws -> T, _ rhs: @autoclosure () throws -> T,
                                 _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let actual = try lhs(), expected = try rhs()
        if actual != expected { XCTFail("\(actual) != \(expected). \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertNotEqual<T: Equatable>(_ lhs: @autoclosure () throws -> T, _ rhs: @autoclosure () throws -> T,
                                    _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try lhs() == rhs() { XCTFail("Expected different values. \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertEqual(_ lhs: @autoclosure () throws -> Double, _ rhs: @autoclosure () throws -> Double,
                    accuracy: Double, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let actual = try lhs(), expected = try rhs()
        if !actual.isFinite || !expected.isFinite || abs(actual - expected) > accuracy {
            XCTFail("\(actual) != \(expected) ± \(accuracy). \(message)", file: file, line: line)
        }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertGreaterThan<T: Comparable>(_ lhs: @autoclosure () throws -> T, _ rhs: @autoclosure () throws -> T,
                                        _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try !(lhs() > rhs()) { XCTFail("Expected greater value. \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertNil<T>(_ value: @autoclosure () throws -> T?, _ message: String = "",
                     file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try value() != nil { XCTFail("Expected nil. \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTAssertNotNil<T>(_ value: @autoclosure () throws -> T?, _ message: String = "",
                        file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try value() == nil { XCTFail("Expected non-nil. \(message)", file: file, line: line) }
    } catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}

func XCTUnwrap<T>(_ value: @autoclosure () throws -> T?, file: StaticString = #filePath,
                  line: UInt = #line) throws -> T {
    guard let value = try value() else {
        XCTFail("Expected non-nil.", file: file, line: line)
        throw CocoaError(.coderValueNotFound)
    }
    return value
}

func XCTAssertThrowsError<T>(_ value: @autoclosure () throws -> T, _ message: String = "",
                             file: StaticString = #filePath, line: UInt = #line,
                             _ handler: (Error) -> Void = { _ in }) {
    do {
        _ = try value()
        XCTFail("Expected an error. \(message)", file: file, line: line)
    } catch { handler(error) }
}

func XCTAssertNoThrow<T>(_ value: @autoclosure () throws -> T, _ message: String = "",
                         file: StaticString = #filePath, line: UInt = #line) {
    do { _ = try value() }
    catch { XCTFail("Unexpected error: \(error). \(message)", file: file, line: line) }
}
