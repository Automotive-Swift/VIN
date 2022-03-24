//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// The Vehicle Identification Number, as standardized in ISO 3779.
public struct VIN: Equatable {

    public static let NumberOfCharacters: Int = 17
    public static let AllowedCharacters: CharacterSet = .init(charactersIn: "ABCDEFGHJKLMNPRSTUVWXYZ0123456789")

    /// The 17 characters as a String.
    public let content: String

    /// Whether the VIN is syntactically valid, i.e. contains of the right kind and amount of characters.
    public var isValid: Bool {
        guard self.content.count == Self.NumberOfCharacters else { return false }
        guard self.content.rangeOfCharacter(from: Self.AllowedCharacters.inverted) == nil else { return false }
        return true
    }

    /// The world manufacturer identifier.
    public var wmi: String {
        guard self.isValid else { return "" }
        let index = self.content.index(self.content.startIndex, offsetBy: 3)
        let sub = self.content[..<index]
        return String(sub)
    }

    /// The vehicle descriptor section.
    public var vds: String {
        guard self.isValid else { return "" }
        let start = self.content.index(self.content.startIndex, offsetBy: 3)
        let end = self.content.index(start, offsetBy: 6)
        let sub = self.content[start..<end]
        return String(sub)
    }

    /// The vehicle identification section.
    public var vis: String {
        guard self.isValid else { return "" }
        let start = self.content.index(self.content.startIndex, offsetBy: 9)
        let sub = self.content[start...]
        return String(sub)
    }

    /// Create a VIN using a `String`.
    public init(content: String) {
        self.content = content
    }
}

extension VIN: Identifiable {

    public var id: String { self.content }
}

extension VIN: CustomStringConvertible {

    public var description: String { self.content }

}

extension VIN: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        self = Self.init(content: value)
    }
}

extension VIN: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.content = try container.decode(String.self)
    }
}

extension VIN: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.content)
    }
}
