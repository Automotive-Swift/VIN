# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build and Test:**
- `swift build` - Build the library
- `swift test` - Run the test suite (21 tests covering validation, parsing, localization, and VIN proposal)
- `swift package generate-xcodeproj` - Generate Xcode project if needed

## Architecture

This is a zero-dependency Swift package for ISO 3779 Vehicle Identification Number (VIN) handling. The architecture centers around:

**VIN Struct** (`Sources/VIN/VIN.swift`):
- Value type with syntactic validation
- Decomposes into WMI (World Manufacturer Identifier, positions 1-3), VDS (Vehicle Descriptor Section, positions 4-9), and VIS (Vehicle Identification Section, positions 10-17)
- Protocol conformances: `Equatable`, `Identifiable`, `CustomStringConvertible`, `ExpressibleByStringLiteral`, `Codable`
- Static `isValid(_:)` convenience method for basic validity checking
- Instance `propose()` method that always returns valid VIN with universal checksum application
- `Unknown` constant ("UNKNWN78901234567") for convenience

**Localization-Driven WMI Data:**
- WMI region/country/manufacturer lookups are powered by extensive localization files (561 manufacturers)
- Located in `Sources/VIN/Resources/{en,de,fr}.lproj/Localizable.strings`
- Fallback mechanism: tries exact WMI match first, then shorter prefixes
- When adding new WMI data, update all localization files to maintain consistency

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