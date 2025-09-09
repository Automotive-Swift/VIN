# VIN Swift Package

A zero-dependency Swift package for handling ISO 3779 Vehicle Identification Numbers (VINs) with comprehensive validation, parsing, and localization support.

## Features

- ✅ **Syntactic validation** according to ISO 3779 standard
- ✅ **Checksum validation** for North American VINs (with universal checksum application via `propose()`)
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
    .package(url: "https://github.com/your-org/VIN-Swift.git", from: "1.0.0")
]
```

Or add via Xcode: File → Add Package Dependencies...

## Basic Usage

```swift
import VIN

// Create VIN instances
let vin: VIN = "1HGBH41JXMN109186"  // String literal
let vin2 = VIN(content: "WAUZZZ4L78D067850")

// Validation
vin.isValid                 // true
VIN.isValid("1HGBH41JX")   // false (too short)

// Access VIN components
vin.wmi                    // "1HG" (World Manufacturer Identifier)
vin.vds                    // "BH41JX" (Vehicle Descriptor Section) 
vin.vis                    // "MN109186" (Vehicle Identification Section)
vin.checksumDigit          // Optional("X")

// Localized manufacturer information
vin.wmiRegion             // "North America"
vin.wmiCountry            // "United States"
vin.wmiManufacturer       // "Honda"
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

## Localization Support

The library includes extensive manufacturer data in multiple languages:

```swift
let audiVin: VIN = "WAUZZZ4L78D067850"
print(audiVin.wmiManufacturer)  // "Audi AG" (English)
// Also available in German and French localizations
```

**Supported languages:**
- English (`en.lproj`)
- German (`de.lproj`) 
- French (`fr.lproj`)

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

1. **Syntactic validation** - Ensures 17 characters from valid set
2. **Semantic validation** - Checksum verification for North American VINs
3. **Component parsing** - Extracts WMI (1-3), VDS (4-9), VIS (10-17)
4. **Localization lookup** - Maps WMI codes to regions, countries, and manufacturers
5. **Smart proposal** - Sanitizes and fixes invalid VINs with universal checksum application

## Testing

Run the comprehensive test suite:

```bash
swift test
```

The package includes 21+ tests covering:
- Validation scenarios
- Component extraction
- Localization lookups
- Proposal functionality
- Protocol conformances
- Edge cases

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