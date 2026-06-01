# Migrating to VIN 2.0.0

`2.0.0` is a deliberate, breaking redesign: the VIN model now exposes **structured,
optional** identity (ISO codes, enums, `nil` for unknown) instead of pre-localized
display strings, and identity accessors decode from **any sufficiently long prefix**
rather than requiring a full, valid 17-character VIN. The previous string-based API
is preserved at the tag `pre-API-change`.

## 1. Bump the dependency (and toolchain)

```diff
- .package(url: "https://github.com/Automotive-Swift/VIN", from: "1.3.0"),
+ .package(url: "https://github.com/Automotive-Swift/VIN", from: "2.0.0"),
```

`2.0.0` requires **Swift 5.9+ / Xcode 15+** (`swift-tools-version` went 5.4 → 5.9).

## 2. Renamed / removed accessors

| Old (≤ 1.3.0) | New (2.0.0) | Notes |
|---|---|---|
| `vin.checksumDigit` | `vin.actualCheckDigit` | Same value (the digit present at position 9). |
| `vin.wmiManufacturer` → `String` (`"?"` if unknown) | `vin.manufacturer` → `String?` (`nil`) | |
| `vin.wmiCountry` → `String` (localized name) | `vin.countryName` → `String?` | Now resolved via `Locale` (every OS language). |
| `vin.wmiRegion` → `String` (continent name) | `vin.region` → `Continent?` | Structured enum; or use `vin.regionCode` (ISO 3166-1 alpha-2). |

```diff
- let digit = vin.checksumDigit                 // Character?
+ let digit = vin.actualCheckDigit              // Character?

- let make = vin.wmiManufacturer                // "Honda" or "?"
- if make != "?" { show(make) }
+ if let make = vin.manufacturer { show(make) } // nil when unknown

- label.text = vin.wmiCountry                   // "United States" / "?"
+ label.text = vin.countryName ?? "—"           // String?

- let area = vin.wmiRegion                      // "North America"
+ let area = vin.region?.rawValue               // Continent? (.northAmerica)
+ // or, usually better:  vin.regionCode -> "US",  vin.flag -> "🇺🇸"
```

## 3. Two behavioral shifts to audit (these compile, but change at runtime)

**`init(content:)` now uppercases.** Lowercase input is no longer rejected, and
`vin.content` is returned uppercased:

```diff
- VIN(content: "1hg…").isValid        // was false
+ VIN(content: "1hg…").isValid        // now true; .content == "1HG…"
```

If you depended on case-sensitive `content`, or on lowercase being treated as
invalid, adjust accordingly.

**`wmi` / `vds` / `vis` decode from any prefix** — they no longer return `""`
unless the VIN is a full, valid 17 characters:

```diff
- VIN(content: "WAU").wmi             // was "" (gated on full validity)
+ VIN(content: "WAU").wmi             // now "WAU"
```

If you used `vin.wmi == ""` as an "invalid VIN" sentinel, switch to `vin.isValid`
or `vin.validity`.

## Unchanged — no migration required

`content`, `validity` (and the `Validity` enum), `isValid`, `isChecksumValid`,
the `wmi` / `vds` / `vis` *names*, `init(content:)`, `validity(of:)`,
`isValid(_:)`, `propose()`, `NumberOfCharacters`, `AllowedCharacters`, `Unknown`,
and the `Codable` / `Identifiable` / `ExpressibleByStringLiteral` /
`CustomStringConvertible` conformances. `Sendable` conformance was **added**
(purely additive).

## New in 2.0.0 (opt-in; no migration needed)

`expectedCheckDigit`, `modelYear`, `assemblyPlant`, `serialNumber`, `regionCode`,
`countryName`, `flag`, `region` / `Continent`. Identity accessors work on partial
input, which makes them suitable for live, as-you-type decoding.
