import Foundation
import UIKit

/// Berify.me SDK main class
public class BerifymeSDK {
    /// Singleton instance
    public static let shared = BerifymeSDK()
    
    private var apiKeyId: String?
    private var secretKey: String?
    private var environment: Environment = .sandbox
    private var sessionToken: String?
    
    private var apiClient: APIClient?
    private var authAPI: AuthAPI?
    private var userAPI: UserAPI?
    private var toolsAPI: ToolsAPI?
    private var clearAPI: ClearAPI?
    private var incodeAPI: IncodeAPI?
    private var biometricsAPI: BiometricsAPI?
    private var walletAPI: WalletAPI?
    
    private init() {}
    
    /// Configure SDK
    /// - Parameters:
    ///   - apiKeyId: API Key ID
    ///   - secretKey: Secret Key
    ///   - environment: Environment configuration
    public func configure(
        apiKeyId: String,
        secretKey: String,
        environment: Environment = .sandbox
    ) {
        self.apiKeyId = apiKeyId
        self.secretKey = secretKey
        self.environment = environment
        
        let baseURL = environment.backendDomain
        self.apiClient = APIClient(baseURL: baseURL)
        
        if let client = apiClient {
            self.authAPI = AuthAPI(client: client)
            self.userAPI = UserAPI(client: client)
            self.toolsAPI = ToolsAPI(client: client)
            self.clearAPI = ClearAPI(client: client)
            self.incodeAPI = IncodeAPI(client: client)
            self.biometricsAPI = BiometricsAPI(client: client)
            self.walletAPI = WalletAPI(client: client)
        }
    }
    
    /// Present verification modal
    /// - Parameters:
    ///   - viewController: Parent view controller
    ///   - verifiedExternalPhoneNumber: Pre-verified external phone number (optional)
    ///   - locale: Incode 介面語系 `en` | `zh-TW` | `mix`（可選；省略時依裝置語系自動選擇繁中或英文）
    ///   - onUpdate: Status update callback
    ///   - onComplete: Completion callback with verification token
    public func presentModal(
        from viewController: UIViewController,
        verifiedExternalPhoneNumber: String? = nil,
        locale: String? = nil,
        onUpdate: ((UpdateData) -> Void)? = nil,
        onComplete: ((String?) -> Void)? = nil
    ) {
        guard let apiKeyId = apiKeyId, let secretKey = secretKey else {
            print("Error: SDK not configured. Please call configure first.")
            return
        }
        
        let modal = BerifymeModalViewController(
            apiKeyId: apiKeyId,
            secretKey: secretKey,
            environment: environment,
            verifiedExternalPhoneNumber: verifiedExternalPhoneNumber,
            locale: locale,
            onUpdate: onUpdate,
            onComplete: onComplete
        )
        
        let navigationController = UINavigationController(rootViewController: modal)
        navigationController.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = navigationController.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let defaultDetentId = UISheetPresentationController.Detent.Identifier("berifyme_default")
                    let defaultDetent = UISheetPresentationController.Detent.custom(identifier: defaultDetentId) { context in
                        context.maximumDetentValue * 0.70
                    }
                    sheet.detents = [defaultDetent, .large()]
                    sheet.selectedDetentIdentifier = defaultDetentId
                } else {
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = true
            }
        }
        
        viewController.present(navigationController, animated: true)
    }
    
    // MARK: - API Access
    
    /// Auth API
    public var auth: AuthAPI? {
        return authAPI
    }
    
    /// User API
    public var user: UserAPI? {
        return userAPI
    }
    
    /// Tools API
    public var tools: ToolsAPI? {
        return toolsAPI
    }
    
    /// Clear API
    public var clear: ClearAPI? {
        return clearAPI
    }
    
    /// Incode API
    public var incode: IncodeAPI? {
        return incodeAPI
    }
    
    /// Biometrics API
    public var biometrics: BiometricsAPI? {
        return biometricsAPI
    }
    
    /// Wallet API
    public var wallet: WalletAPI? {
        return walletAPI
    }
}
