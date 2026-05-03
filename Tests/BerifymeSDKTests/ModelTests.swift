import XCTest
@testable import BerifymeSDK

final class ModelTests: XCTestCase {
    
    // MARK: - Environment Tests
    
    func testEnvironmentEnum() {
        // Test all environment values
        XCTAssertEqual(Environment.sandbox.rawValue, "sandbox")
        XCTAssertEqual(Environment.staging.rawValue, "staging")
        XCTAssertEqual(Environment.idv.rawValue, "idv")
    }
    
    func testEnvironmentBackendDomains() {
        let sandboxDomain = Environment.sandbox.backendDomain
        XCTAssertTrue(sandboxDomain.contains("sandbox"))
        XCTAssertTrue(sandboxDomain.hasPrefix("https://"))
        
        let stagingDomain = Environment.staging.backendDomain
        XCTAssertTrue(stagingDomain.contains("staging"))
        
        let idvDomain = Environment.idv.backendDomain
        XCTAssertTrue(idvDomain.contains("backend"))
    }
    
    func testEnvironmentWebviewDomains() {
        let sandboxWebview = Environment.sandbox.webviewDomain
        XCTAssertTrue(sandboxWebview.contains("sandbox"))
        
        let stagingWebview = Environment.staging.webviewDomain
        XCTAssertTrue(stagingWebview.contains("staging"))
        
        let idvWebview = Environment.idv.webviewDomain
        XCTAssertTrue(idvWebview.contains("idv"))
    }
    
    // MARK: - User Model Tests
    
    func testUserInitialization() {
        let user = User(
            id: "user-123",
            isActive: true,
            email: "user@example.com",
            phoneNumber: "+886912345678",
            age: 30,
            fullName: "John Doe"
        )
        
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.isActive, true)
        XCTAssertEqual(user.email, "user@example.com")
        XCTAssertEqual(user.phoneNumber, "+886912345678")
        XCTAssertEqual(user.fullName, "John Doe")
        XCTAssertEqual(user.age, 30)
    }
    
    func testUserWithOptionalFields() {
        let user = User(id: "user-123")
        
        XCTAssertEqual(user.id, "user-123")
        XCTAssertNil(user.isActive)
        XCTAssertNil(user.email)
        XCTAssertNil(user.phoneNumber)
    }
    
    func testUserCodable() throws {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            phoneNumber: "+886912345678"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, decodedUser.id)
        XCTAssertEqual(user.email, decodedUser.email)
        XCTAssertEqual(user.phoneNumber, decodedUser.phoneNumber)
    }
    
    // MARK: - PageStatus Tests
    
    func testPageStatusRawValues() {
        XCTAssertEqual(PageStatus.loading.rawValue, -1)
        XCTAssertEqual(PageStatus.sendSNS.rawValue, 0)
        XCTAssertEqual(PageStatus.allSet.rawValue, 20)
        XCTAssertEqual(PageStatus.faceAgeEstimation.rawValue, 21)
    }

    func testFaceAgeEstimationReactNativeMapping() {
        XCTAssertEqual(PageStatus.faceAgeEstimation.reactNativeValue, 2.6, accuracy: 0.0001)
        XCTAssertEqual(PageStatus.fromReactNativeValue(2.6), PageStatus.faceAgeEstimation)
    }
    
    func testPageStatusPageNames() {
        let statuses: [PageStatus] = [
            .loading, .sendSNS, .verifyNewUser, .vender,
            .clearOnboarding, .incodeOnBoarding, .faceAgeEstimation, .allSet
        ]
        
        for status in statuses {
            XCTAssertFalse(status.pageName.isEmpty, "PageStatus \(status.rawValue) should have a page name")
        }
    }
    
    // MARK: - VerificationStatus Tests
    
    func testVerificationStatus() {
        XCTAssertEqual(VerificationStatus.pending.rawValue, "PENDING")
        XCTAssertEqual(VerificationStatus.onboarding.rawValue, "ONBOARDING")
        XCTAssertEqual(VerificationStatus.login.rawValue, "LOGIN")
    }
    
    // MARK: - ActionType Tests
    
    func testActionType() {
        XCTAssertEqual(ActionType.onboarding.rawValue, "ONBOARDING")
        XCTAssertEqual(ActionType.login.rawValue, "LOGIN")
    }
    
    // MARK: - UpdateData Tests
    
    func testUpdateData() {
        let pageInfo = UpdateData.PageInfo(pageName: "TestPage")
        let updateData = UpdateData(page: pageInfo, message: "Test message")
        
        XCTAssertEqual(updateData.page?.pageName, "TestPage")
        XCTAssertEqual(updateData.message, "Test message")
    }
    
    func testUpdateDataWithoutMessage() {
        let pageInfo = UpdateData.PageInfo(pageName: "TestPage")
        let updateData = UpdateData(page: pageInfo)
        
        XCTAssertEqual(updateData.page?.pageName, "TestPage")
        XCTAssertNil(updateData.message)
        XCTAssertNil(updateData.sessionExpiredRetry)
    }
    
    func testUpdateDataSessionExpiredRetry() {
        let pageInfo = UpdateData.PageInfo(pageName: "SessionExpiredRetry")
        let updateData = UpdateData(
            page: pageInfo,
            message: UpdateData.sessionExpiredRetryMessage,
            sessionExpiredRetry: true
        )
        XCTAssertEqual(updateData.sessionExpiredRetry, true)
        XCTAssertEqual(updateData.message, "SESSION_EXPIRED_RETRY")
    }
}
