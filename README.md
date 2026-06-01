# VIN Swift Package

A zero-dependency Swift package for handling ISO 3779 Vehicle Identification Numbers (VINs) with comprehensive validation, parsing, and structured identity decoding.

> **Upgrading from 1.x?** `2.0.0` is a breaking redesign — see [MIGRATION.md](MIGRATION.md).

## Features

- ✅ **Tri-state validity checking** - Distinguishes between invalid, valid, and checksum-validated VINs
- ✅ **Syntactic validation** according to ISO 3779 standard
- ✅ **Checksum validation** for all VINs (recognizing it's not mandatory worldwide)
- ✅ **VIN decomposition** into WMI, VDS, and VIS components
- ✅ **Localized manufacturer lookup** supporting 561+ manufacturers across multiple languages
- ✅ **Smart VIN proposal** that sanitizes and fixes invalid VINs
- ✅ **Zero dependencies** - pure Swift implementation
- ✅ **Protocol conformances**: `Equatable`, `Identifiable`, `CustomStringConvertible`, `ExpressibleByStringLiteral`, `Codable`

## Installation

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Automotive-Swift/VIN.git", from: "1.0.0")
]
```

Or add via Xcode: File → Add Package Dependencies → enter `https://github.com/Automotive-Swift/VIN`

## Basic Usage

```swift
import VIN

// Create VIN instances
let vin: VIN = "1HGBH41JXMN109186"  // String literal
let vin2 = VIN(content: "WAUZZZ4L78D067850")

// Tri-state validity checking
vin.validity                          // .validWithChecksum
vin2.validity                         // .validWithChecksum or .valid (depends on checksum)
VIN.validity(of: "1HGBH41J0MN109186") // .valid (wrong checksum but syntactically valid)
VIN.validity(of: "INVALID")           // .invalid (wrong length/characters)

// Validity enum helpers
vin.validity.isSyntacticallyValid     // true
vin.validity.hasValidChecksum         // true

// Simple boolean validation (backward compatible)
vin.isValid                           // true (syntactically valid, regardless of checksum)
VIN.isValid("1HGBH41JX")             // false (too short)

// Checksum validation
vin.isChecksumValid                   // true
vin.actualCheckDigit                  // Optional("X") — the digit present at position 9
vin.expectedCheckDigit                // Optional("X") — the computed digit

// Access VIN components (decode from any sufficiently long prefix)
vin.wmi                              // "1HG" (World Manufacturer Identifier)
vin.vds                              // "BH41JX" (Vehicle Descriptor Section)
vin.vis                              // "MN109186" (Vehicle Identification Section)
vin.modelYear                        // Optional(2021) — position 10
vin.assemblyPlant                    // Optional("N") — position 11
vin.serialNumber                     // Optional("109186") — positions 12–17

// Structured identity (nil when unknown)
vin.regionCode                       // Optional("US") — ISO 3166-1 alpha-2
vin.countryName                      // Optional("United States") — localized via Locale
vin.flag                             // Optional("🇺🇸")
vin.region                           // Optional(.northAmerica)
vin.manufacturer                     // Optional("Honda")
```

## Tri-State Validity Model

VINs use a three-state validity enum to reflect that checksum validation is not mandatory worldwide:

```swift
public enum Validity {
    case invalid              // Syntactically invalid (wrong length, invalid characters)
    case valid                // Syntactically valid, checksum not verified or incorrect
    case validWithChecksum    // Syntactically valid AND checksum verified
}
```

This design recognizes that:
- **North American VINs** (US, Canada, Mexico) mandate checksum validation
- **European and other regions** may not require checksums
- Applications can choose validation strictness based on their requirements

```swift
let usVin: VIN = "1HGBH41JXMN109186"
switch usVin.validity {
case .invalid:
    print("Not a valid VIN format")
case .valid:
    print("Valid VIN syntax, but checksum failed")
case .validWithChecksum:
    print("Fully validated VIN with correct checksum")
}

// For backward compatibility, isValid returns true for both .valid and .validWithChecksum
let syntacticallyValid = usVin.isValid  // true for both .valid and .validWithChecksum
```

## Smart VIN Proposal

The `propose()` method always returns a valid VIN by sanitizing and fixing common issues:

```swift
// Fix invalid characters
let invalidVin = VIN(content: "1hgbh41jxmn1o9i86")  // lowercase, contains O and I
let fixed = invalidVin.propose()
// Result: Valid VIN with I→1, O→0, uppercase conversion, correct checksum

// Handle partial VINs
let partial = VIN(content: "WBA")
let completed = partial.propose()
// Result: "WBAAAAAAAA0000000" (padded and checksum applied)

// Generate fantasy VIN from invalid input
let garbage = VIN(content: "!@#$%^&*()")
let fantasy = garbage.propose()
// Result: "1VWAA7A36FC000001" (legal fantasy VIN)

// Universal checksum application (not just North American)
let european = VIN(content: "WVWZZZ3CZJE123456")
let withChecksum = european.propose()
// Result: European VIN with proper checksum calculated
```

## Identity & localization

Manufacturer names ship as a built-in Swift directory (650+ WMIs) and are returned as proper nouns. Country localization is delegated to the operating system: `regionCode` is an ISO 3166-1 alpha-2 code, and `countryName` resolves it through `Locale` — so country names localize automatically in *every* OS language, with no bundled string tables to maintain.

```swift
let audiVin: VIN = "WAUZZZ4L78D067850"
audiVin.manufacturer   // "Audi"
audiVin.regionCode     // "DE"
audiVin.countryName    // "Germany" (or "Deutschland", … depending on Locale)
audiVin.flag           // "🇩🇪"
audiVin.region         // .europe
```

## Constants

```swift
VIN.Unknown                    // "UNKNWN78901234567" - convenience constant
VIN.NumberOfCharacters         // 17
VIN.AllowedCharacters         // Valid VIN character set (excludes I, O, Q)
```

## Platform Support

- **iOS** 13.0+
- **macOS** 11.0+
- **tvOS** 13.0+
- **watchOS** 6.0+
- **Linux** (available but commented out in Package.swift)

## Architecture

The library is built around a single `VIN` struct that provides:

1. **Tri-state validation** - Distinguishes between invalid, syntactically valid, and checksum-validated VINs
2. **Syntactic validation** - Ensures 17 characters from valid set (excludes I, O, Q)
3. **Checksum verification** - Universal checksum calculation for all VINs
4. **Component parsing** - Extracts WMI (1-3), VDS (4-9), VIS (10-17)
5. **Localization lookup** - Maps WMI codes to regions, countries, and manufacturers
6. **Smart proposal** - Sanitizes and fixes invalid VINs with universal checksum application

## Testing

Run the comprehensive test suite:

```bash
swift test
```

The package includes 26+ tests covering:
- Tri-state validity checking
- Validation scenarios (syntactic and checksum)
- Component extraction
- Localization lookups
- Proposal functionality
- Protocol conformances
- Edge cases
- Backward compatibility

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`swift test`)
4. Commit your changes
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is available under the MIT License. See LICENSE file for details.

---

**Note**: This is a micro-library focused specifically on VIN handling. For broader automotive data needs, consider the full Automotive-Swift suite.