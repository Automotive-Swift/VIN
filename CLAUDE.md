# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build and Test:**
- `swift build` - Build the library
- `swift test` - Run the test suite (covers tri-state validity, checksum math, parsing, region/manufacturer/model-year decoding, partial-input decoding, and VIN proposal)
- `swift package generate-xcodeproj` - Generate Xcode project if needed

## Architecture

This is a zero-dependency Swift package for ISO 3779 Vehicle Identification Number (VIN) handling. The architecture centers around:

**VIN Struct** (`Sources/VIN/VIN.swift`):
- Value type with tri-state validity model (`VIN.Validity` enum)
- Decomposes into WMI (World Manufacturer Identifier, positions 1-3), VDS (Vehicle Descriptor Section, positions 4-9), and VIS (Vehicle Identification Section, positions 10-17)
- Protocol conformances: `Equatable`, `Hashable`, `Identifiable`, `CustomStringConvertible`, `ExpressibleByStringLiteral`, `Codable`
- `validity` property returns `.invalid`, `.valid`, or `.validWithChecksum`
- `isValid` property for backward compatibility (returns `true` for both `.valid` and `.validWithChecksum`)
- `isChecksumValid` property for explicit checksum verification
- Static `validity(of:)` method to check validity state without creating instance
- Static `isValid(_:)` convenience method for basic syntactic validation
- Instance `propose()` method that always returns valid VIN with universal checksum application
- `Unknown` constant ("UNKNWN78901234567") for convenience

**Validity Model:**
The library uses a tri-state validity enum to reflect that checksum validation is not mandatory worldwide:
- `.invalid` - Syntactically invalid (wrong length, contains I/O/Q, or other invalid characters)
- `.valid` - Syntactically valid per ISO 3779, but checksum not verified or incorrect
- `.validWithChecksum` - Syntactically valid AND checksum verified
This design recognizes that North American VINs mandate checksums while European and other regions may not

**WMI / region data (structured, not localized strings):**
- Manufacturer directory: `Sources/VIN/VINManufacturers.swift` (650+ WMIs, Swift `[String: String]`). Names are proper nouns, not localized. Lookup tries the 3-character WMI, then the 2-character prefix. Add new makers here.
- Region/country: `Sources/VIN/VINRegions.swift` ports the ISO 3780 Annex A ranges to ISO 3166-1 alpha-2 codes (`regionCode`); country *names* are derived via `Locale` (so they localize in every OS language with no string tables). Also holds the `Continent` enum and the position-10 model-year table.
- Identity accessors decode from any sufficiently long prefix (≥1/≥2/≥3/≥10 chars) — no full-VIN gate — so they work for live input.
- The old `.lproj` string tables and `wmiRegion`/`wmiCountry`/`wmiManufacturer`/`checksumDigit` accessors were removed in the v2 redesign (see tag `pre-API-change`).

## Development Guidelines

**Testing:**
- Tests use real VIN examples for validation
- When adding features, follow the existing test patterns in `Tests/VINTests/VINTests.swift`
- Ensure all tests pass before committing changes

**Code Patterns:**
- Follow the existing struct-based, protocol-oriented design
- Maintain the library's zero-dependency nature
- Use `NSLocalizedString` with `bundle: .module` for any user-facing strings
- Keep the API surface minimal and focused on VIN handling

**Platform Support:**
- Minimum deployment targets: macOS 11.0, iOS 13.0, tvOS 13.0, watchOS 6.0
- Linux support is available but currently commented out in Package.swift