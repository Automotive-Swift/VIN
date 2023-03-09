//
// VIN. (C) 2016-2023 Dr. Michael 'Mickey' Lauer <mickey@Vanille.de>
//
import Foundation

/// The Vehicle Identification Number, as standardized in ISO 3779.
public struct VIN: Equatable {

    public static let NumberOfCharacters: Int = 17
    public static let AllowedCharacters: CharacterSet = .init(charactersIn: "ABCDEFGHJKLMNPRSTUVWXYZ0123456789")
    public static let Unknown: VIN = .init(content: "UNKNWN78901234567")

    /// The 17 characters as a String.
    public let content: String

    /// Whether the VIN is syntactically valid, i.e. contains the right kind and amount of characters.
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

    /// The world manufacturer region.
    public var wmiRegion: String {
        let wmi = self.wmi
        guard wmi != "" else { return "" }
        let index = wmi.index(self.content.startIndex, offsetBy: 1)
        let prefix = wmi[..<index]
        let fullKey = "ISO3780_WMI_REGION_\(prefix)"
        return self.computeLocalization(forKey: fullKey)
    }

    /// The world manufacturer country.
    public var wmiCountry: String {
        let wmi = self.wmi
        guard wmi != "" else { return "" }
        let index = wmi.index(self.content.startIndex, offsetBy: 2)
        let prefix = wmi[..<index]
        let fullKey = "ISO3780_WMI_COUNTRY_\(prefix)"
        return self.computeLocalization(forKey: fullKey)
    }

    // The world manufacturer manufacturer
    public var wmiManufacturer: String {
        let wmi = self.wmi
        guard wmi != "" else { return "" }
        let fullKey = "ISO3780_WMI_MANUFACTURER_\(wmi)"
        return self.computeLocalization(forKey: fullKey)
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

    /// Convenience method, if all you want to check for is validity.
    public static func isValid(_ vin: String) -> Bool { VIN(content: vin).isValid }
}

private extension VIN {

    func computeLocalization(forKey key: String) -> String {

        var string = NSLocalizedString(key, bundle: .module, value: "?", comment: "")
        if string != "?" { return string }

        var shorterKey = key
        shorterKey.removeLast()
        string = NSLocalizedString(shorterKey, bundle: .module, value: "?", comment: "")
        return string
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
