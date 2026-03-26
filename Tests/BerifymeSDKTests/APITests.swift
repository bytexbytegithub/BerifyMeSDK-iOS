import XCTest
@testable import BerifymeSDK

final class APITests: XCTestCase {
    var apiClient: APIClient!
    
    override func setUp() {
        super.setUp()
        // Use test environment
        apiClient = APIClient(baseURL: "https://sandbox-backend.berify.me")
    }
    
    override func tearDown() {
        apiClient = nil
        super.tearDown()
    }
    
    // MARK: - Environment Tests
    
    func testEnvironmentBackendDomain() {
        XCTAssertEqual(Environment.sandbox.backendDomain, "https://sandbox-backend.berify.me")
        XCTAssertEqual(Environment.staging.backendDomain, "https://staging-backend.berify.me")
        XCTAssertEqual(Environment.idv.backendDomain, "https://backend.berify.me")
    }
    
    func testEnvironmentWebviewDomain() {
        XCTAssertEqual(Environment.sandbox.webviewDomain, "https://sandbox.berify.me")
        XCTAssertEqual(Environment.staging.webviewDomain, "https://staging.berify.me")
        XCTAssertEqual(Environment.idv.webviewDomain, "https://idv.berify.me")
    }
    
    // MARK: - PhoneNumberProcessor Tests
    
    func testPhoneNumberProcessor() {
        let phone1 = "+886912345678"
        let processed1 = PhoneNumberProcessor.process(phone1)
        XCTAssertEqual(processed1, "886912345678")
        
        let phone2 = "+886 912 345 678"
        let processed2 = PhoneNumberProcessor.process(phone2)
        XCTAssertEqual(processed2, "886912345678")
        
        let phone3 = "0912-345-678"
        let processed3 = PhoneNumberProcessor.process(phone3)
        XCTAssertEqual(processed3, "0912345678")
    }
    
    func testPhoneNumberValidation() {
        XCTAssertTrue(PhoneNumberProcessor.isValid("+886912345678"))
        XCTAssertTrue(PhoneNumberProcessor.isValid("0912345678"))
        XCTAssertFalse(PhoneNumberProcessor.isValid("123"))
        XCTAssertFalse(PhoneNumberProcessor.isValid(""))
    }
    
    // MARK: - User Model Tests
    
    func testUserModel() {
        let user = User(
            id: "test-id",
            isActive: true,
            email: "test@example.com",
            phoneNumber: "+886912345678",
            fullName: "Test User"
        )
        
        XCTAssertEqual(user.id, "test-id")
        XCTAssertEqual(user.isActive, true)
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.phoneNumber, "+886912345678")
        XCTAssertEqual(user.fullName, "Test User")
    }
    
    func testUserEquality() {
        let user1 = User(id: "1", phoneNumber: "+886912345678")
        let user2 = User(id: "1", phoneNumber: "+886912345678")
        let user3 = User(id: "2", phoneNumber: "+886912345678")
        
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
    
    // MARK: - PageStatus Tests
    
    func testPageStatusPageName() {
        XCTAssertEqual(PageStatus.loading.pageName, "Loading")
        XCTAssertEqual(PageStatus.sendSNS.pageName, "AuthStart")
        XCTAssertEqual(PageStatus.allSet.pageName, "VerifySuccess")
    }
    
    // MARK: - API Client Tests
    
    func testAPIClientInitialization() {
        let client = APIClient(baseURL: "https://api.example.com")
        XCTAssertNotNil(client)
    }
    
    // Note: Real network request tests require Mock or test server
    // Here we only test basic structure
}
