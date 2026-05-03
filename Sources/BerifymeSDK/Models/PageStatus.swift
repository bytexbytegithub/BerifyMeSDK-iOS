import Foundation

/// Page status enum
/// Note: Swift Int enum does not support decimal values, so integers are used here
/// Logical order is consistent with react-native-sdk
public enum PageStatus: Int, Codable {
    case loading = -1
    case sendSNS = 0
    case verifiedExternalPhoneNumber = 1  // RN: 0.1
    case verifyNewUser = 2                 // RN: 1
    case vender = 3                        // RN: 1.1
    case idOrPassport = 4                  // RN: 1.2
    case verifyUser = 5                    // RN: 1.5
    case authIdOnboarding = 6              // RN: 2
    case clearOnboarding = 7               // RN: 2.1
    case incodeOnBoarding = 8              // RN: 2.2
    case sumsubOnBoarding = 9              // RN: 2.3
    case veriffOnBoarding = 10             // RN: 2.4
    case yotiOnBoarding = 11               // RN: 2.5
    case authidLogin = 12                  // RN: 3
    case clearLogin = 13                    // RN: 4
    case incodeLogin = 14                  // RN: 5
    case clearLoginAllSet = 15             // RN: 6
    case clearOnboardingAllSet = 16        // RN: 7
    case sumsubLogin = 17                  // RN: 8
    case veriffLogin = 18                  // RN: 9
    case yotiLogin = 19                    // RN: 11
    case allSet = 20                       // RN: 10
    case faceAgeEstimation = 21           // RN: 2.6（Incode 臉齡）
    
    /// String representation of page status
    public var pageName: String {
        switch self {
        case .loading:
            return "Loading"
        case .sendSNS:
            return "AuthStart"
        case .verifiedExternalPhoneNumber:
            return "VerifiedExternalPhoneNumber"
        case .verifyNewUser:
            return "VerifyNewUser"
        case .vender:
            return "Vender"
        case .idOrPassport:
            return "BerifymeChooseIdOrPassport"
        case .verifyUser:
            return "VerifyUser"
        case .authIdOnboarding:
            return "BerifymeOnboarding"
        case .clearOnboarding:
            return "ClearOnboarding"
        case .incodeOnBoarding:
            return "IncodeOnBoarding"
        case .sumsubOnBoarding:
            return "SumsubOnBoarding"
        case .veriffOnBoarding:
            return "VeriffOnBoarding"
        case .yotiOnBoarding:
            return "YotiOnBoarding"
        case .authidLogin:
            return "BerifymeLogin"
        case .clearLogin:
            return "ClearLogin"
        case .incodeLogin:
            return "IncodeLogin"
        case .clearLoginAllSet:
            return "ClearLoginVerifySuccess"
        case .clearOnboardingAllSet:
            return "ClearOnboardingVerifySuccess"
        case .sumsubLogin:
            return "SumsubLogin"
        case .veriffLogin:
            return "VeriffLogin"
        case .yotiLogin:
            return "YotiLogin"
        case .allSet:
            return "VerifySuccess"
        case .faceAgeEstimation:
            return "FaceAgeEstimation"
        }
    }
    
    /// Value corresponding to react-native-sdk (for cross-platform integration)
    /// Returns closest value since Swift Int does not support decimals
    public var reactNativeValue: Double {
        switch self {
        case .loading: return -1.0
        case .sendSNS: return 0.0
        case .verifiedExternalPhoneNumber: return 0.1
        case .verifyNewUser: return 1.0
        case .vender: return 1.1
        case .idOrPassport: return 1.2
        case .verifyUser: return 1.5
        case .authIdOnboarding: return 2.0
        case .clearOnboarding: return 2.1
        case .incodeOnBoarding: return 2.2
        case .sumsubOnBoarding: return 2.3
        case .veriffOnBoarding: return 2.4
        case .yotiOnBoarding: return 2.5
        case .faceAgeEstimation: return 2.6
        case .authidLogin: return 3.0
        case .clearLogin: return 4.0
        case .incodeLogin: return 5.0
        case .clearLoginAllSet: return 6.0
        case .clearOnboardingAllSet: return 7.0
        case .sumsubLogin: return 8.0
        case .veriffLogin: return 9.0
        case .yotiLogin: return 11.0
        case .allSet: return 10.0
        }
    }
    
    /// Map backend vendor string to login PageStatus (single source of truth; used by SendSMS, VerifyUser, VerifiedExternalPhoneNumber)
    public static func loginStatus(forVendor vendor: String) -> PageStatus? {
        switch vendor.lowercased() {
        case "authid": return .authidLogin
        case "clear": return .clearLogin
        case "incode": return .incodeLogin
        case "sumsub": return .sumsubLogin
        case "veriff": return .veriffLogin
        case "yoti": return .yotiLogin
        default: return nil
        }
    }
    
    /// Create PageStatus from react-native-sdk value
    public static func fromReactNativeValue(_ value: Double) -> PageStatus? {
        switch value {
        case -1.0: return .loading
        case 0.0: return .sendSNS
        case 0.1: return .verifiedExternalPhoneNumber
        case 1.0: return .verifyNewUser
        case 1.1: return .vender
        case 1.2: return .idOrPassport
        case 1.5: return .verifyUser
        case 2.0: return .authIdOnboarding
        case 2.1: return .clearOnboarding
        case 2.2: return .incodeOnBoarding
        case 2.3: return .sumsubOnBoarding
        case 2.4: return .veriffOnBoarding
        case 2.5: return .yotiOnBoarding
        case 2.6: return .faceAgeEstimation
        case 3.0: return .authidLogin
        case 4.0: return .clearLogin
        case 5.0: return .incodeLogin
        case 6.0: return .clearLoginAllSet
        case 7.0: return .clearOnboardingAllSet
        case 8.0: return .sumsubLogin
        case 9.0: return .veriffLogin
        case 11.0: return .yotiLogin
        case 10.0: return .allSet
        default: return nil
        }
    }
}

/// Verification status
public enum VerificationStatus: String, Codable {
    case pending = "PENDING"
    case onboarding = "ONBOARDING"
    case login = "LOGIN"
}

/// Action type
public enum ActionType: String, Codable {
    case onboarding = "ONBOARDING"
    case login = "LOGIN"
}

/// Update data
public struct UpdateData: Codable {
    public let page: PageInfo?
    public let message: String?
    /// 與 WebSDK 對齊：使用者因 session 過期按 Try again、即將重新建立 token 時為 true
    public let sessionExpiredRetry: Bool?
    
    public struct PageInfo: Codable {
        public let pageName: String
        
        public init(pageName: String) {
            self.pageName = pageName
        }
    }
    
    public init(page: PageInfo? = nil, message: String? = nil, sessionExpiredRetry: Bool? = nil) {
        self.page = page
        self.message = message
        self.sessionExpiredRetry = sessionExpiredRetry
    }
    
    /// `onUpdate` 的 `detail.message` 會等於此字串（與 `sessionExpiredRetry == true` 一併使用）
    public static let sessionExpiredRetryMessage = "SESSION_EXPIRED_RETRY"
}
