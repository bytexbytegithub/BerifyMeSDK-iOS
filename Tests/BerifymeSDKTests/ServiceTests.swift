import XCTest
@testable import BerifymeSDK

final class ServiceTests: XCTestCase {
    
    // MARK: - PhoneNumberProcessor Tests
    
    func testPhoneNumberProcessing() {
        // Align RN processPhoneNumber: trim, remove + prefix, digits only, country prefix rules
        let phone1 = "+886912345678"
        let result1 = PhoneNumberProcessor.process(phone1)
        XCTAssertEqual(result1, "886912345678")
        
        let phone2 = "+886 912 345 678"
        let result2 = PhoneNumberProcessor.process(phone2)
        XCTAssertEqual(result2, "886912345678")
        
        let phone3 = "+886-912-345-678"
        let result3 = PhoneNumberProcessor.process(phone3)
        XCTAssertEqual(result3, "886912345678")
        
        let phone4 = "+886 (912) 345-678"
        let result4 = PhoneNumberProcessor.process(phone4)
        XCTAssertEqual(result4, "886912345678")
        
        // Taiwan: 88609… → 8869… (align WebSDK normalizeTaiwanDigitsAfterCountryCode)
        let phone5 = "8860912345678"
        let result5 = PhoneNumberProcessor.process(phone5)
        XCTAssertEqual(result5, "886912345678")

        let twNational = "0912345678"
        XCTAssertEqual(
            PhoneNumberProcessor.process(twNational, countryIso2: "tw"),
            "886912345678"
        )
        XCTAssertEqual(PhoneNumberProcessor.process(twNational, countryIso2: "us"), "0912345678")
    }
    
    func testPhoneNumberValidation() {
        // Valid phone numbers
        XCTAssertTrue(PhoneNumberProcessor.isValid("+886912345678"))
        XCTAssertTrue(PhoneNumberProcessor.isValid("+1234567890"))
        XCTAssertTrue(PhoneNumberProcessor.isValid("0912345678"))
        
        // Invalid phone numbers
        XCTAssertFalse(PhoneNumberProcessor.isValid("123")) // Too short
        XCTAssertFalse(PhoneNumberProcessor.isValid("")) // Empty string
        XCTAssertFalse(PhoneNumberProcessor.isValid("abc")) // Contains letters
    }
    
    func testPhoneNumberEdgeCases() {
        // Test edge cases
        let minLength = "12345678" // 8 digits
        XCTAssertTrue(PhoneNumberProcessor.isValid(minLength))
        
        let maxLength = "+123456789012345" // 15 digits (with +)
        XCTAssertTrue(PhoneNumberProcessor.isValid(maxLength))
        
        let tooShort = "1234567" // 7 digits
        XCTAssertFalse(PhoneNumberProcessor.isValid(tooShort))
        
        let tooLong = "+1234567890123456" // 16 digits
        XCTAssertFalse(PhoneNumberProcessor.isValid(tooLong))
    }
}
