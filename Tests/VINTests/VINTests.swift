import Testing
import Foundation
@testable import VIN

@Suite("VIN Tests")
struct VINTests {
    
    @Test("Unknown VIN is valid")
    func testUnknown() {
        #expect(VIN.Unknown.isValid)
    }
    
    @Test("Valid VINs pass validation", arguments: [
        "1FMEE5DH5NLA77159",
        "1G6DU57V190152065",
        "MMBJJKL10LH016787",
        "JN1TFNT32A0041590",
        "WP1ZZZ9PZ8LA33027",
        "WBAJA9105KB304806",
        "WF0AXXWPMAEA04617",
        "2BCCE8140HB506017",
        "WAUZZZ4L78D067850",
        "1FTYR14C2YTA84254",
        "MNTBB7A96E6014216",
        "1FADP3F20DL237413",
    ])
    func testValid(vinString: String) {
        let vin = VIN(stringLiteral: vinString)
        #expect(vin.isValid, "VIN \(vinString) should be valid")
    }
    
    @Test("Invalid VINs fail validation")
    func testInvalid() {
        let invalid = [
            ("FMEE5DH5NLA77159", "too short"),
            ("21G6DU57V190152065", "too long"),
            ("MMBJJKL1OLH016787", "contains 'O'"),
            ("JN1TFNT3IA0041590", "contains 'I'"),
            ("WP1ZZZ9PQ8LA33027", "contains 'Q'"),
        ]
        
        for (vinString, reason) in invalid {
            let vin = VIN(stringLiteral: vinString)
            #expect(!vin.isValid, "VIN \(vinString) should be invalid - \(reason)")
        }
    }
    
    @Test("Checksum digit getter")
    func testChecksumDigitGetter() {
        let vin1: VIN = "1FMEE5DH5NLA77159"
        #expect(vin1.checksumDigit == "5", "Checksum digit should be '5'")
        
        let vin2: VIN = "WAUZZZ4L78D067850"
        #expect(vin2.checksumDigit == "7", "Checksum digit should be '7'")
        
        let vin3: VIN = "1G1YY25RX85104727"
        #expect(vin3.checksumDigit == "X", "Checksum digit should be 'X'")
        
        let invalidVin: VIN = "INVALID"
        #expect(invalidVin.checksumDigit == nil, "Invalid VIN should return nil checksum digit")
    }
    
    @Test("Checksum validation")
    func testChecksumValidation() {
        // Test North American VINs with valid checksums
        let validNorthAmerican = [
            "1HGBH41JXMN109186",  // Valid Honda VIN (checksum X)
            "1FTFW1ET9DFC10312",  // Valid Ford VIN (checksum 9)
            "2C3KA43R08H129584",  // Valid Chrysler VIN (checksum 0)
        ]
        
        for vinString in validNorthAmerican {
            let vin = VIN(content: vinString)
            #expect(vin.isChecksumValid, "VIN \(vinString) should have valid checksum")
        }
        
        // Test North American VINs with invalid checksums
        let invalidChecksum = [
            "1HGBH41J0MN109186",  // Invalid checksum (0 instead of X)
            "1FTFW1ET0DFC10312",  // Invalid checksum (0 instead of 9)
        ]
        
        for vinString in invalidChecksum {
            let vin = VIN(content: vinString)
            #expect(!vin.isChecksumValid, "VIN \(vinString) should have invalid checksum")
        }
        
        // Test that European VINs don't fail on checksum (they don't use checksums)
        let europeanVin = VIN(content: "WAUZZZ4L78D067850")
        #expect(europeanVin.isValid, "European VIN should be valid without checksum validation")
    }
    
    @Test("Propose function always returns valid VIN")
    func testPropose() {
        // Test basic sanitization with lowercase
        let vin1 = VIN(content: "1hgbh41jxmn109186")
        let proposed1 = vin1.propose()
        #expect(proposed1.content.allSatisfy { $0.isUppercase || $0.isNumber }, "Should convert to uppercase")
        #expect(proposed1.isValid, "Proposed VIN should be valid")
        #expect(proposed1.isChecksumValid, "Should have valid checksum")
        
        // Test character substitution (I -> 1, O -> 0, Q -> 0)
        let vin2 = VIN(content: "IHGBH41JXMNIO9I86")
        let proposed2 = vin2.propose()
        #expect(!proposed2.content.contains("I"), "Should not contain I")
        #expect(!proposed2.content.contains("O"), "Should not contain O")
        #expect(!proposed2.content.contains("Q"), "Should not contain Q")
        #expect(proposed2.isValid, "Proposed VIN should be valid")
        #expect(proposed2.isChecksumValid, "Should have valid checksum")
        
        // Test padding with zeros (too short)
        let vin3 = VIN(content: "1HGBH41JX")
        let proposed3 = vin3.propose()
        #expect(proposed3.content.count == 17, "Should pad to 17 characters")
        // Note: Position 9 (index 8) is the checksum, so it will be recalculated
        #expect(proposed3.content.hasPrefix("1HGBH41J"), "Should preserve content before checksum")
        #expect(proposed3.content.suffix(8) == "00000000", "Should pad with zeros after checksum")
        #expect(proposed3.isValid, "Should be valid after padding")
        #expect(proposed3.isChecksumValid, "Should have valid checksum")
        
        // Test truncation (too long)
        let vin4 = VIN(content: "1HGBH41JXMN109186EXTRA")
        let proposed4 = vin4.propose()
        #expect(proposed4.content.count == 17, "Should truncate to 17 characters")
        #expect(proposed4.isValid, "Should be valid after truncation")
        #expect(proposed4.isChecksumValid, "Should have valid checksum")
        
        // Test checksum fixing for all VINs (not just North American)
        let vin5 = VIN(content: "WAUZZZ8X0CB000001")  // European VIN with wrong checksum
        let proposed5 = vin5.propose()
        #expect(proposed5.isChecksumValid, "Should have valid checksum even for European VIN")
        #expect(proposed5.isValid, "Should be valid after checksum fix")
        
        // Test spaces removal
        let vin6 = VIN(content: "1HG BH4 1JX MN1 091 86")
        let proposed6 = vin6.propose()
        #expect(!proposed6.content.contains(" "), "Should remove spaces")
        #expect(proposed6.content.count == 17, "Should have 17 characters after space removal")
        #expect(proposed6.isChecksumValid, "Should have valid checksum")
        
        // Test fantasy VIN generation for completely invalid input
        let vin7 = VIN(content: "!@#$%^&*()")
        let proposed7 = vin7.propose()
        #expect(proposed7.content.count == 17, "Should generate 17-character VIN")
        #expect(proposed7.isValid, "Fantasy VIN should be valid")
        #expect(proposed7.isChecksumValid, "Fantasy VIN should have valid checksum")
        
        // Test empty string generates fantasy VIN
        let vin8 = VIN(content: "")
        let proposed8 = vin8.propose()
        #expect(proposed8.content.count == 17, "Should generate 17-character VIN from empty")
        #expect(proposed8.isValid, "Fantasy VIN from empty should be valid")
        #expect(proposed8.isChecksumValid, "Fantasy VIN should have valid checksum")
    }
    
    @Test("Description returns VIN content")
    func testDescription() {
        let string = "MMBJJKL10LH016787"
        let vin: VIN = "MMBJJKL10LH016787"
        #expect("\(vin)" == string)
    }
    
    @Test("VIN equality")
    func testEquality() {
        let vin1: VIN = "1FADP3F20DL237413"
        let vin2: VIN = "1FADP3F20DL237413"
        #expect(vin1 == vin2)
    }
    
    @Test("VIN inequality")
    func testInequality() {
        let vin1: VIN = "WP1ZZZ9PZ8LA33027"
        let vin2: VIN = "1FADP3F20DL237413"
        #expect(vin1 != vin2)
    }
    
    @Test("Codable conformance")
    func testCodable() throws {
        let vin1: VIN = "WP1ZZZ9PZ8LA33027"
        let data = try JSONEncoder().encode(vin1)
        let vin2: VIN = try JSONDecoder().decode(VIN.self, from: data)
        #expect(vin1 == vin2)
        
        // Test that the JSON is just a string
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString == "\"WP1ZZZ9PZ8LA33027\"")
    }
    
    @Test("VIN parts extraction")
    func testParts() throws {
        let vin: VIN = "WAUZZZ8X7CB000001"
        
        #expect(vin.wmi == "WAU")
        #expect(vin.vds == "ZZZ8X7")
        #expect(vin.vis == "CB000001")
        #expect(vin.checksumDigit == "7")
        
        // Test with invalid VIN
        let invalidVin: VIN = "INVALID"
        #expect(invalidVin.wmi == "", "Invalid VIN should return empty WMI")
        #expect(invalidVin.vds == "", "Invalid VIN should return empty VDS")
        #expect(invalidVin.vis == "", "Invalid VIN should return empty VIS")
    }
    
    @Test("WMI region lookup")
    func testRegion() throws {
        let vin: VIN = "WAUZZZ8X7CB000001"
        #expect(vin.wmiRegion != "?")
        
        // Test known regions
        let usVin: VIN = "1HGBH41JXMN109186"
        #expect(usVin.wmiRegion != "?", "US VIN should have a region")
        
        let euVin: VIN = "WBAJA9105KB304806"
        #expect(euVin.wmiRegion != "?", "EU VIN should have a region")
    }
    
    @Test("WMI country lookup")
    func testCountry() throws {
        let vin: VIN = "WAUZZZ8X7CB000001"
        #expect(vin.wmiCountry != "?")
        
        // Test known countries
        let usVin: VIN = "1HGBH41JXMN109186"
        #expect(usVin.wmiCountry != "?", "US VIN should have a country")
        
        let germanVin: VIN = "WBAJA9105KB304806"
        #expect(germanVin.wmiCountry != "?", "German VIN should have a country")
    }
    
    @Test("WMI manufacturer lookup")
    func testManufacturer() throws {
        let vin: VIN = "WAUZZZ8X7CB000001"
        #expect(vin.wmiManufacturer != "?")
        
        // Test known manufacturers
        let hondaVin: VIN = "1HGBH41JXMN109186"
        #expect(hondaVin.wmiManufacturer != "?", "Honda VIN should have a manufacturer")
        
        let bmwVin: VIN = "WBAJA9105KB304806"
        #expect(bmwVin.wmiManufacturer != "?", "BMW VIN should have a manufacturer")
    }
    
    @Test("Identifiable conformance")
    func testIdentifiable() {
        let vin: VIN = "1HGBH41JXMN109186"
        #expect(vin.id == "1HGBH41JXMN109186", "ID should be the VIN content")
    }
    
    @Test("ExpressibleByStringLiteral conformance")
    func testExpressibleByStringLiteral() {
        let vin: VIN = "1HGBH41JXMN109186"
        #expect(vin.content == "1HGBH41JXMN109186")
        
        // Test that it works in different contexts
        func acceptVIN(_ vin: VIN) -> String {
            return vin.content
        }
        #expect(acceptVIN("WAUZZZ8X7CB000001") == "WAUZZZ8X7CB000001")
    }
    
    @Test("Static isValid method")
    func testStaticIsValid() {
        #expect(VIN.isValid("1HGBH41JXMN109186"))
        #expect(!VIN.isValid("INVALID"))
        #expect(!VIN.isValid("1HGBH41JXMN10918"))  // Too short
        #expect(!VIN.isValid("1HGBH41JXMN1091866"))  // Too long
    }
    
    @Test("Edge cases")
    func testEdgeCases() {
        // Test empty string
        let emptyVin = VIN(content: "")
        #expect(!emptyVin.isValid)
        #expect(emptyVin.checksumDigit == nil)
        #expect(emptyVin.wmi == "")
        #expect(emptyVin.vds == "")
        #expect(emptyVin.vis == "")
        
        // Test VIN with exactly 17 characters but all invalid
        let allInvalidVin = VIN(content: "IIIIIIIIIIIIIIIII")
        #expect(!allInvalidVin.isValid)
        
        // Test VIN with mixed valid/invalid characters
        let mixedVin = VIN(content: "1HGBH41JXMN10918I")
        #expect(!mixedVin.isValid)
    }
    
    @Test("Propose function comprehensive tests")
    func testProposeComprehensive() {
        // Test that propose always returns the same result for the same input
        let vin1 = VIN(content: "ABC123")
        let proposed1a = vin1.propose()
        let proposed1b = vin1.propose()
        #expect(proposed1a.content == proposed1b.content, "Should be deterministic")
        
        // Test that already valid VINs get checksum applied
        let validVin = VIN(content: "1HGBH41JXMN109186")
        let proposedValid = validVin.propose()
        #expect(proposedValid.isValid, "Valid VIN should remain valid")
        #expect(proposedValid.isChecksumValid, "Should have valid checksum")
        
        // Test mixed alphanumeric with invalid characters
        let mixedVin = VIN(content: "1@2#3$4%5^6&7*8(9)")
        let proposedMixed = mixedVin.propose()
        #expect(proposedMixed.content.count == 17, "Should be 17 characters")
        #expect(proposedMixed.isValid, "Should be valid")
        #expect(proposedMixed.isChecksumValid, "Should have valid checksum")
        
        // Test VIN with only invalid characters creates fantasy VIN
        let onlyInvalidVin = VIN(content: "IQO!@#$%^&*()")
        let proposedInvalid = onlyInvalidVin.propose()
        // After character substitution IQO becomes 100, then padded and checksum applied
        #expect(proposedInvalid.content.hasPrefix("10000000"), "Should substitute I->1, Q->0, O->0 and pad")
        #expect(proposedInvalid.isValid, "Should be valid")
        #expect(proposedInvalid.isChecksumValid, "Should have valid checksum")
        
        // Test that Unknown VIN can be proposed
        let unknownProposed = VIN.Unknown.propose()
        #expect(unknownProposed.isValid, "Proposed Unknown should be valid")
        #expect(unknownProposed.isChecksumValid, "Proposed Unknown should have valid checksum")
        
        // Test partial VIN gets padded and checksum applied
        let partialVin = VIN(content: "WBA")
        let proposedPartial = partialVin.propose()
        #expect(proposedPartial.content.hasPrefix("WBA"), "Should preserve original prefix")
        #expect(proposedPartial.content.count == 17, "Should be padded to 17 characters")
        #expect(proposedPartial.isChecksumValid, "Should have valid checksum")
        
        // Test that European VINs get checksum applied
        let europeanVin = VIN(content: "WVWZZZ3CZJE123456")
        let proposedEuropean = europeanVin.propose()
        #expect(proposedEuropean.isChecksumValid, "European VIN should get valid checksum")
        
        // Test that Asian VINs get checksum applied
        let japaneseVin = VIN(content: "JN1AZ4EH7DM430111")
        let proposedJapanese = japaneseVin.propose()
        #expect(proposedJapanese.isChecksumValid, "Japanese VIN should get valid checksum")
        
        // Test very long string gets truncated properly
        let veryLongVin = VIN(content: String(repeating: "A", count: 100))
        let proposedLong = veryLongVin.propose()
        #expect(proposedLong.content.count == 17, "Should truncate to 17 characters")
        #expect(proposedLong.isChecksumValid, "Should have valid checksum after truncation")
    }
    
    @Test("Propose preserves valid parts of VIN")
    func testProposePreservation() {
        // Test that valid WMI is preserved
        let vinWithValidWMI = VIN(content: "1HG")
        let proposed = vinWithValidWMI.propose()
        #expect(proposed.content.hasPrefix("1HG"), "Should preserve valid WMI")
        
        // Test that valid characters are kept in order
        let vinWithMixedValid = VIN(content: "1@H#G$B%H^4&1*J(X)")
        let proposedMixed = vinWithMixedValid.propose()
        // Note: Position 9 (index 8) is the checksum position, so X gets replaced with calculated checksum
        #expect(proposedMixed.content.hasPrefix("1HGBH41J"), "Should preserve valid characters before checksum")
        // The X is at position 9 which is the checksum position and will be recalculated
        
        // Test case conversion preserves content
        let lowerCaseVin = VIN(content: "wauzzz4l78d067850")
        let proposedLower = lowerCaseVin.propose()
        #expect(proposedLower.content.hasPrefix("WAUZZZ4L7"), "Should convert to uppercase while preserving content")
    }
    
    @Test("Propose checksum calculation for all regions")
    func testProposeChecksumAllRegions() {
        // North American VIN
        let usVin = VIN(content: "1FADP3F20DL237413")
        let proposedUS = usVin.propose()
        #expect(proposedUS.isChecksumValid, "US VIN should have valid checksum")
        
        // European VIN (traditionally doesn't use checksum, but our propose applies it)
        let germanVin = VIN(content: "WBAJA9105KB304806")
        let proposedGerman = germanVin.propose()
        #expect(proposedGerman.isChecksumValid, "German VIN should have valid checksum after propose")
        
        // Asian VIN
        let koreanVin = VIN(content: "KMHWF35H66A023847")
        let proposedKorean = koreanVin.propose()
        #expect(proposedKorean.isChecksumValid, "Korean VIN should have valid checksum")
        
        // South American VIN  
        let brazilianVin = VIN(content: "9BWAG91048T123456")
        let proposedBrazilian = brazilianVin.propose()
        #expect(proposedBrazilian.isChecksumValid, "Brazilian VIN should have valid checksum")
    }
}