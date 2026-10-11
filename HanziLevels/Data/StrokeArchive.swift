import Foundation

/// Indexes record boundaries without decoding stroke paths or median arrays.
/// JSON inside each record is decoded and validated when that character is requested.
struct StrokeArchive: Sendable {
    private let data: Data
    private let ranges: [String: Range<Data.Index>]

    init(data: Data) throws {
        var cursor = Cursor(data: data)
        ranges = try cursor.indexRecords()
        self.data = data
    }

    func contains(_ characterID: String) -> Bool { ranges[characterID] != nil }

    func record(for characterID: String) -> Data? {
        ranges[characterID].map { data.subdata(in: $0) }
    }

    private struct Cursor {
        let data: Data
        var position: Data.Index

        init(data: Data) {
            self.data = data
            position = data.startIndex
        }

        mutating func indexRecords() throws -> [String: Range<Data.Index>] {
            var records: [String: Range<Data.Index>] = [:]
            try consume(0x7B) // {
            skipWhitespace()
            if peek == 0x7D {
                position += 1
            } else {
                while true {
                    skipWhitespace()
                    let keyStart = position
                    try skipString()
                    let key = try JSONDecoder().decode(String.self, from: data.subdata(in: keyStart..<position))
                    try consume(0x3A) // :
                    skipWhitespace()
                    guard peek == 0x7B, records[key] == nil else { throw invalidArchive }
                    records[key] = try skipObject()
                    skipWhitespace()
                    if peek == 0x7D {
                        position += 1
                        break
                    }
                    try consume(0x2C) // ,
                }
            }
            skipWhitespace()
            guard position == data.endIndex else { throw invalidArchive }
            return records
        }

        private var peek: UInt8? { position < data.endIndex ? data[position] : nil }
        private var invalidArchive: LibraryError { .invalidContent("Invalid stroke archive.") }

        private mutating func skipWhitespace() {
            while let byte = peek, [0x20, 0x09, 0x0A, 0x0D].contains(byte) { position += 1 }
        }

        private mutating func consume(_ byte: UInt8) throws {
            skipWhitespace()
            guard peek == byte else { throw invalidArchive }
            position += 1
        }

        private mutating func skipString() throws {
            guard peek == 0x22 else { throw invalidArchive }
            position += 1
            while let byte = peek {
                position += 1
                if byte == 0x22 { return }
                if byte == 0x5C { // An escaped byte cannot terminate this string.
                    guard peek != nil else { throw invalidArchive }
                    position += 1
                } else if byte < 0x20 {
                    throw invalidArchive
                }
            }
            throw invalidArchive
        }

        private mutating func skipObject() throws -> Range<Data.Index> {
            let start = position
            var closingBytes: [UInt8] = []
            while let byte = peek {
                switch byte {
                case 0x22:
                    try skipString()
                    continue
                case 0x7B: closingBytes.append(0x7D) // { }
                case 0x5B: closingBytes.append(0x5D) // [ ]
                case 0x7D, 0x5D:
                    guard closingBytes.popLast() == byte else { throw invalidArchive }
                default: break
                }
                position += 1
                if closingBytes.isEmpty { return start..<position }
            }
            throw invalidArchive
        }
    }
}
