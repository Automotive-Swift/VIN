//
// VIN. (C) 2016-2023 Dr. Michael 'Mickey' Lauer <mickey@Vanille.de>
//
import Foundation

/// The Vehicle Identification Number, as standardized in ISO 3779.
public struct VIN: Equatable, Hashable {

    public static let NumberOfCharacters: Int = 17
    public static let AllowedCharacters: CharacterSet = .init(charactersIn: "ABCDEFGHJKLMNPRSTUVWXYZ0123456789")
    public static let Unknown: VIN = .init(content: "UNKNWN78901234567")

    /// The 17 characters as a String.
    public let content: String

    /// Whether the VIN is syntactically valid, i.e. contains the right kind and amount of characters.
    /// For North American VINs, this also validates the checksum digit.
    public var isValid: Bool {
        guard self.content.count == Self.NumberOfCharacters else { return false }
        guard self.content.rangeOfCharacter(from: Self.AllowedCharacters.inverted) == nil else { return false }
        
        // Additional checksum validation for North American VINs
        // North American VINs typically start with 1-5 (US, Canada, Mexico)
        if let firstChar = self.content.first,
           let firstDigit = Int(String(firstChar)),
           (1...5).contains(firstDigit) {
            return self.isChecksumValid
        }
        
        return true
    }
    
    /// Whether the checksum digit is valid according to the VIN checksum algorithm.
    public var isChecksumValid: Bool {
        guard self.content.count == Self.NumberOfCharacters else { return false }
        
        let calculated = Self.calculateChecksum(for: self.content)
        return self.checksumDigit == calculated
    }
    
    /// Calculate the character value for checksum calculation.
    private static func characterValue(for char: Character) -> Int? {
        switch char {
        case "0"..."9":
            return Int(String(char))
        case "A", "J":
            return 1
        case "B", "K", "S":
            return 2
        case "C", "L", "T":
            return 3
        case "D", "M", "U":
            return 4
        case "E", "N", "V":
            return 5
        case "F", "W":
            return 6
        case "G", "P", "X":
            return 7
        case "H", "Y":
            return 8
        case "R", "Z":
            return 9
        default:
            return nil
        }
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
    
    /// The checksum digit (9th character, part of VDS).
    /// For North American VINs, this should be a calculated check digit.
    /// Returns nil if VIN is invalid.
    public var checksumDigit: Character? {
        guard self.content.count == Self.NumberOfCharacters else { return nil }
        let index = self.content.index(self.content.startIndex, offsetBy: 8)
        return self.content[index]
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
    
    /// Propose a valid VIN based on the current VIN's data.
    /// Always returns a valid VIN by:
    /// 1. Using current data as starting point
    /// 2. Sanitizing invalid characters
    /// 3. Padding or truncating to 17 characters
    /// 4. Always applying checksum calculation (for all VINs, not just North American)
    /// 5. Creating a fantasy VIN if no valid data exists
    public func propose() -> VIN {
        // Start with current content, or empty if none
        var sanitized = self.content.uppercased()
        
        // Remove spaces
        sanitized = sanitized.replacingOccurrences(of: " ", with: "")
        
        // Replace disallowed characters with similar allowed ones
        sanitized = sanitized.replacingOccurrences(of: "I", with: "1")
        sanitized = sanitized.replacingOccurrences(of: "O", with: "0")
        sanitized = sanitized.replacingOccurrences(of: "Q", with: "0")
        
        // Remove any remaining invalid characters
        sanitized = String(sanitized.filter { Self.AllowedCharacters.contains(String($0).unicodeScalars.first!) })
        
        // If we have no valid characters at all, create a fantasy VIN
        if sanitized.isEmpty {
            // Create a fantasy but legal VIN
            // Using "1VW" as WMI (fictional Volkswagen US plant)
            // Random but plausible VDS and VIS
            sanitized = "1VWAA7A30FC000001"
        }
        
        // Ensure we have exactly 17 characters
        if sanitized.count < Self.NumberOfCharacters {
            // Pad with zeros at the end
            sanitized += String(repeating: "0", count: Self.NumberOfCharacters - sanitized.count)
        } else if sanitized.count > Self.NumberOfCharacters {
            // Truncate to 17 characters
            let index = sanitized.index(sanitized.startIndex, offsetBy: Self.NumberOfCharacters)
            sanitized = String(sanitized[..<index])
        }
        
        // Always calculate and apply the checksum (not just for North American VINs)
        sanitized = Self.fixChecksum(for: sanitized)
        
        return VIN(content: sanitized)
    }
    
    /// Calculate the correct checksum for a VIN string.
    private static func calculateChecksum(for vinString: String) -> Character? {
        guard vinString.count == Self.NumberOfCharacters else { return nil }
        
        let weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]
        var sum = 0
        
        // Calculate sum for all positions except checksum position (index 8)
        for (index, char) in vinString.enumerated() {
            if index == 8 { continue } // Skip checksum position
            guard let value = Self.characterValue(for: char) else { return nil }
            sum += value * weights[index]
        }
        
        let checkDigit = sum % 11
        return checkDigit == 10 ? "X" : Character(String(checkDigit))
    }
    
    /// Fix the checksum digit for a given VIN string.
    private static func fixChecksum(for vinString: String) -> String {
        guard vinString.count == Self.NumberOfCharacters else { return vinString }
        
        guard let checksumChar = calculateChecksum(for: vinString) else { return vinString }
        
        // Replace character at position 9 (index 8) with correct checksum
        var chars = Array(vinString)
        chars[8] = checksumChar
        return String(chars)
    }
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
