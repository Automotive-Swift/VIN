//
// VIN. (C) 2016-2023 Dr. Michael 'Mickey' Lauer <mickey@Vanille.de>
//
import Foundation

/// The Vehicle Identification Number, as standardized in ISO 3779.
///
/// Construction is lenient and normalizing: the content is uppercased so that a
/// VIN typed in lowercase is still recognized, but invalid characters and wrong
/// lengths are preserved so that `validity` can report them. Identity accessors
/// (`wmi`, `regionCode`, `manufacturer`, `modelYear`, …) decode from any prefix
/// of sufficient length, which makes them usable for live, as-you-type input.
public struct VIN: Equatable, Hashable, Sendable {

    /// Represents the validity state of a VIN.
    public enum Validity: Equatable, Hashable, Sendable {
        /// The VIN is syntactically invalid (wrong length, invalid characters).
        case invalid
        /// The VIN is syntactically valid but the checksum is incorrect or not applicable.
        case valid
        /// The VIN is syntactically valid AND has a correct checksum.
        case validWithChecksum

        /// Whether the VIN meets basic syntactic requirements.
        public var isSyntacticallyValid: Bool {
            switch self {
                case .invalid: return false
                case .valid, .validWithChecksum: return true
            }
        }

        /// Whether the VIN has a verified checksum.
        public var hasValidChecksum: Bool {
            switch self {
                case .validWithChecksum: return true
                case .invalid, .valid: return false
            }
        }
    }

    public static let NumberOfCharacters: Int = 17
    public static let AllowedCharacters: CharacterSet = .init(charactersIn: "ABCDEFGHJKLMNPRSTUVWXYZ0123456789")
    public static let Unknown: VIN = .init(content: "UNKNWN78901234567")

    /// The (uppercased) VIN characters as a `String`.
    public let content: String

    /// Create a VIN from a `String`. The value is uppercased; other characters
    /// are kept verbatim so `validity` can still flag them.
    public init(content: String) {
        self.content = content.uppercased()
    }

    // MARK: Validity & checksum

    /// The validity state of the VIN.
    public var validity: Validity {
        guard self.content.count == Self.NumberOfCharacters else { return .invalid }
        guard self.content.rangeOfCharacter(from: Self.AllowedCharacters.inverted) == nil else { return .invalid }
        return self.isChecksumValid ? .validWithChecksum : .valid
    }

    /// Whether the VIN is syntactically valid (correct length and characters), regardless of checksum.
    public var isValid: Bool { self.validity.isSyntacticallyValid }

    /// Whether the checksum digit matches the value computed from the other positions.
    public var isChecksumValid: Bool {
        guard let actual = self.actualCheckDigit, let expected = self.expectedCheckDigit else { return false }
        return actual == expected
    }

    /// The check digit actually present at position 9, or `nil` if absent.
    public var actualCheckDigit: Character? {
        guard self.content.count >= 9 else { return nil }
        return Array(self.content)[8]
    }

    /// The check digit computed from the other positions (requires a full 17-character VIN).
    public var expectedCheckDigit: Character? {
        Self.calculateChecksum(for: self.content)
    }

    /// Whether position 9 carries a *mandatory* ISO 3779 check digit.
    ///
    /// The check digit is required only for VINs assigned to North America (leading WMI
    /// character `1`–`5`, i.e. ``region`` is ``Continent/northAmerica``). Manufacturers in
    /// other regions use that position freely — VW VINs, for instance, place a `Z` filler
    /// there — so a non-matching ``expectedCheckDigit`` on such a VIN is not a defect.
    /// Decodes from the leading character, so it is usable for live, as-you-type input.
    public var requiresCheckDigit: Bool { self.region == .northAmerica }

    // MARK: Structure (decode from any sufficiently long prefix)

    /// The World Manufacturer Identifier (positions 1–3, or fewer if the prefix is shorter).
    public var wmi: String { String(self.content.prefix(3)) }

    /// The Vehicle Descriptor Section (positions 4–9).
    public var vds: String { String(self.content.dropFirst(3).prefix(6)) }

    /// The Vehicle Identification Section (positions 10–17).
    public var vis: String { String(self.content.dropFirst(9)) }

    /// The model-year code decoded from position 10 (North American cycle; see ``vinModelYearCodes``).
    public var modelYear: Int? {
        guard self.content.count >= 10 else { return nil }
        return vinModelYearCodes[Array(self.content)[9]]
    }

    /// The assembly-plant character at position 11, or `nil` if absent.
    public var assemblyPlant: Character? {
        guard self.content.count >= 11 else { return nil }
        return Array(self.content)[10]
    }

    /// The sequential serial number (positions 12–17), or `nil` if absent.
    public var serialNumber: String? {
        guard self.content.count >= 12 else { return nil }
        return String(self.content.dropFirst(11).prefix(6))
    }

    // MARK: Identity

    /// ISO 3166-1 alpha-2 country code of the manufacturer, decoded from the first two WMI characters.
    public var regionCode: String? {
        guard self.content.count >= 2 else { return nil }
        return vinRegionCode(forPrefix: String(self.content.prefix(2)))
    }

    /// Localized country name for ``regionCode`` (via `Locale`), falling back to the raw code.
    public var countryName: String? {
        guard let regionCode = self.regionCode else { return nil }
        return Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
    }

    /// Flag emoji built from ``regionCode``'s regional-indicator symbols.
    public var flag: String? {
        guard let regionCode = self.regionCode else { return nil }
        return regionCode.uppercased().unicodeScalars.reduce(into: "") { result, scalar in
            guard scalar.value >= 0x41, scalar.value <= 0x5A,
                  let indicator = Unicode.Scalar(0x1F1E6 + scalar.value - 0x41) else { return }
            result.unicodeScalars.append(indicator)
        }
    }

    /// Continent of the manufacturer, from the leading WMI character.
    public var region: Continent? {
        self.content.first.flatMap(Continent.init(wmiLeadingCharacter:))
    }

    /// Manufacturer name for the WMI (full 3-character, else 2-character prefix), or `nil` when unknown.
    public var manufacturer: String? {
        if self.content.count >= 3, let name = vinManufacturers[String(self.content.prefix(3))] { return name }
        if self.content.count >= 2, let name = vinManufacturers[String(self.content.prefix(2))] { return name }
        return nil
    }

    // MARK: Convenience

    /// Convenience: the validity state of a VIN string.
    public static func validity(of vin: String) -> Validity { VIN(content: vin).validity }

    /// Convenience: whether a VIN string is syntactically valid (regardless of checksum).
    public static func isValid(_ vin: String) -> Bool { VIN(content: vin).isValid }

    /// Propose a valid VIN derived from the current content: sanitize invalid
    /// characters, pad/truncate to 17, and apply a correct checksum. Falls back
    /// to a fantasy-but-legal VIN when no usable data remains.
    public func propose() -> VIN {
        var sanitized = self.content.uppercased()
        sanitized = sanitized.replacingOccurrences(of: " ", with: "")
        sanitized = sanitized.replacingOccurrences(of: "I", with: "1")
        sanitized = sanitized.replacingOccurrences(of: "O", with: "0")
        sanitized = sanitized.replacingOccurrences(of: "Q", with: "0")
        sanitized = String(sanitized.filter { Self.AllowedCharacters.contains($0.unicodeScalars.first!) })

        if sanitized.isEmpty {
            sanitized = "1VWAA7A30FC000001"
        }

        if sanitized.count < Self.NumberOfCharacters {
            sanitized += String(repeating: "0", count: Self.NumberOfCharacters - sanitized.count)
        } else if sanitized.count > Self.NumberOfCharacters {
            sanitized = String(sanitized.prefix(Self.NumberOfCharacters))
        }

        return VIN(content: Self.fixChecksum(for: sanitized))
    }

    // MARK: Checksum math

    private static func characterValue(for char: Character) -> Int? {
        switch char {
            case "0"..."9": return Int(String(char))
            case "A", "J": return 1
            case "B", "K", "S": return 2
            case "C", "L", "T": return 3
            case "D", "M", "U": return 4
            case "E", "N", "V": return 5
            case "F", "W": return 6
            case "G", "P", "X": return 7
            case "H", "Y": return 8
            case "R", "Z": return 9
            default: return nil
        }
    }

    private static let checksumWeights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

    /// Calculate the correct check digit for a full 17-character VIN string.
    private static func calculateChecksum(for vinString: String) -> Character? {
        guard vinString.count == Self.NumberOfCharacters else { return nil }
        var sum = 0
        for (index, char) in vinString.enumerated() where index != 8 {
            guard let value = Self.characterValue(for: char) else { return nil }
            sum += value * Self.checksumWeights[index]
        }
        let checkDigit = sum % 11
        return checkDigit == 10 ? "X" : Character(String(checkDigit))
    }

    /// Replace position 9 with the correct check digit.
    private static func fixChecksum(for vinString: String) -> String {
        guard vinString.count == Self.NumberOfCharacters,
              let checksumChar = calculateChecksum(for: vinString) else { return vinString }
        var chars = Array(vinString)
        chars[8] = checksumChar
        return String(chars)
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

extension VIN: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(content: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.content)
    }
}
