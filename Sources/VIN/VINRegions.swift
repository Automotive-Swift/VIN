//
// VIN. (C) 2016-2023 Dr. Michael 'Mickey' Lauer <mickey@Vanille.de>
//

/// Continent of a VIN's manufacturer, derived from the first WMI character per
/// ISO 3780 Annex A.
public enum Continent: String, Equatable, Hashable, Sendable, CaseIterable {
    case africa
    case asia
    case europe
    case northAmerica
    case oceania
    case southAmerica

    /// The continent assigned to a leading WMI character, or `nil` for `I`/`O`/`Q`.
    init?(wmiLeadingCharacter c: Character) {
        switch c {
            case "A"..."H": self = .africa
            case "J"..."R": self = .asia
            case "S"..."Z": self = .europe
            case "1"..."5": self = .northAmerica
            case "6", "7": self = .oceania
            case "8", "9", "0": self = .southAmerica
            default: return nil
        }
    }
}

/// VIN character collation used by ISO 3780 region ranges: letters (excluding
/// `I`, `O`, `Q`) first, then digits `1`–`9` and finally `0`.
private let vinCharacterOrder = "ABCDEFGHJKLMNPRSTUVWXYZ1234567890"

private func vinRank(_ prefix: String) -> Int? {
    let characters = Array(prefix.prefix(2))
    guard characters.count == 2,
          let first = vinCharacterOrder.firstIndex(of: characters[0]),
          let second = vinCharacterOrder.firstIndex(of: characters[1]) else { return nil }
    let firstRank = vinCharacterOrder.distance(from: vinCharacterOrder.startIndex, to: first)
    let secondRank = vinCharacterOrder.distance(from: vinCharacterOrder.startIndex, to: second)
    return firstRank * 100 + secondRank
}

/// Returns the ISO 3166-1 alpha-2 country code for a WMI's first two characters.
func vinRegionCode(forPrefix prefix: String) -> String? {
    guard let rank = vinRank(prefix) else { return nil }
    return vinRegionRanges.first { rank >= $0.low && rank <= $0.high }?.regionCode
}

private struct VINRegionRange {
    let low: Int
    let high: Int
    let regionCode: String

    init(_ low: String, _ high: String, _ regionCode: String) {
        self.low = vinRank(low) ?? 0
        self.high = vinRank(high) ?? 0
        self.regionCode = regionCode
    }
}

/// First/second WMI character ranges mapped to ISO 3166-1 alpha-2 codes,
/// following the ISO 3780 Annex A geographic allocation. Whole-letter regions
/// span `xA`…`x0`; single-point assignments use identical bounds.
private let vinRegionRanges: [VINRegionRange] = [
    // Africa
    .init("AA", "AH", "ZA"), .init("AJ", "AK", "CI"), .init("AL", "AM", "LS"),
    .init("AN", "AP", "BW"), .init("AR", "AS", "NA"), .init("AT", "AU", "MG"),
    .init("AV", "AW", "MU"), .init("AX", "AY", "TN"), .init("AZ", "A1", "CY"),
    .init("A2", "A3", "ZW"), .init("A4", "A5", "MZ"),
    .init("BA", "BB", "AO"), .init("BC", "BC", "ET"), .init("BF", "BG", "KE"),
    .init("BH", "BH", "RW"), .init("BL", "BL", "NG"), .init("BR", "BR", "DZ"),
    .init("BT", "BT", "SZ"), .init("BU", "BU", "UG"), .init("B3", "B4", "LY"),
    .init("CA", "CB", "EG"), .init("CF", "CG", "MA"), .init("CL", "CM", "ZM"),
    // Asia
    .init("HA", "H0", "CN"),
    .init("JA", "J0", "JP"),
    .init("KF", "KH", "IL"), .init("KL", "KR", "KR"), .init("KS", "KT", "JO"),
    .init("K1", "K3", "KR"), .init("K5", "K5", "KG"),
    .init("LA", "L0", "CN"),
    .init("MA", "ME", "IN"), .init("MF", "MK", "ID"), .init("ML", "MR", "TH"),
    .init("MS", "MS", "MM"), .init("MU", "MU", "MN"), .init("MX", "MX", "KZ"),
    .init("MY", "M0", "IN"),
    .init("NA", "NE", "IR"), .init("NF", "NG", "PK"), .init("NJ", "NJ", "IQ"),
    .init("NL", "NR", "TR"), .init("NS", "NT", "UZ"), .init("NV", "NV", "AZ"),
    .init("NX", "NX", "TJ"), .init("NY", "NY", "AM"), .init("N1", "N5", "IR"),
    .init("N7", "N8", "TR"),
    .init("PA", "PC", "PH"), .init("PF", "PG", "SG"), .init("PL", "PR", "MY"),
    .init("PS", "PT", "BD"), .init("PV", "PV", "KH"), .init("P5", "P0", "IN"),
    .init("RA", "RB", "AE"), .init("RF", "RK", "TW"), .init("RL", "RN", "VN"),
    .init("RP", "RP", "LA"), .init("RS", "RT", "SA"), .init("R1", "R7", "HK"),
    // Europe
    .init("EA", "E0", "RU"),
    .init("SA", "SM", "GB"), .init("SN", "ST", "DE"), .init("SU", "SZ", "PL"),
    .init("S1", "S2", "LV"), .init("S3", "S3", "GE"), .init("S4", "S4", "IS"),
    .init("TA", "TH", "CH"), .init("TJ", "TP", "CZ"), .init("TR", "TV", "HU"),
    .init("TW", "T2", "PT"), .init("T3", "T5", "RS"), .init("T6", "T6", "AD"),
    .init("T7", "T8", "NL"),
    .init("UA", "UC", "ES"), .init("UH", "UM", "DK"), .init("UN", "UR", "IE"),
    .init("UU", "UX", "RO"), .init("U1", "U2", "MK"), .init("U5", "U7", "SK"),
    .init("U8", "U0", "BA"),
    .init("VA", "VE", "AT"), .init("VF", "VR", "FR"), .init("VS", "VW", "ES"),
    .init("VX", "V2", "FR"), .init("V3", "V5", "HR"), .init("V6", "V8", "EE"),
    .init("WA", "W0", "DE"),
    .init("XA", "XC", "BG"), .init("XD", "XE", "RU"), .init("XF", "XH", "GR"),
    .init("XJ", "XK", "RU"), .init("XL", "XR", "NL"), .init("XS", "XW", "RU"),
    .init("XX", "XY", "LU"), .init("XZ", "X1", "RU"),
    .init("YA", "YE", "BE"), .init("YF", "YK", "FI"), .init("YN", "YN", "MT"),
    .init("YS", "YW", "SE"), .init("YX", "Y2", "NO"), .init("Y3", "Y5", "BY"),
    .init("Y6", "Y9", "UA"),
    .init("ZA", "ZU", "IT"), .init("ZX", "ZZ", "SI"), .init("Z1", "Z1", "SM"),
    .init("Z3", "Z5", "LT"), .init("Z6", "Z0", "RU"),
    // North America
    .init("1A", "10", "US"), .init("2A", "20", "CA"),
    .init("3A", "3X", "MX"), .init("34", "34", "NI"), .init("35", "35", "DO"),
    .init("36", "36", "HN"), .init("37", "37", "PA"), .init("38", "39", "PR"),
    .init("4A", "40", "US"), .init("5A", "50", "US"), .init("7A", "70", "US"),
    // Oceania
    .init("6A", "6X", "AU"), .init("6Y", "61", "NZ"),
    // South America
    .init("8A", "8E", "AR"), .init("8F", "8G", "CL"), .init("8L", "8N", "EC"),
    .init("8S", "8W", "PE"), .init("8X", "8Z", "VE"), .init("82", "82", "BO"),
    .init("84", "84", "CR"),
    .init("9A", "9E", "BR"), .init("9F", "9G", "CO"), .init("9S", "9V", "UY"),
    .init("91", "90", "BR"),
]

/// Model-year code for VIN position 10 (North American 30-year cycle).
///
/// Codes repeat every 30 years (e.g. `Y` is 2000 and again 2030); this table
/// uses the 2000–2029 window. Callers needing disambiguation must use other
/// signals (e.g. an authoritative online decode).
let vinModelYearCodes: [Character: Int] = [
    "A": 2010, "B": 2011, "C": 2012, "D": 2013, "E": 2014, "F": 2015,
    "G": 2016, "H": 2017, "J": 2018, "K": 2019, "L": 2020, "M": 2021,
    "N": 2022, "P": 2023, "R": 2024, "S": 2025, "T": 2026, "V": 2027,
    "W": 2028, "X": 2029, "Y": 2000, "1": 2001, "2": 2002, "3": 2003,
    "4": 2004, "5": 2005, "6": 2006, "7": 2007, "8": 2008, "9": 2009,
]
