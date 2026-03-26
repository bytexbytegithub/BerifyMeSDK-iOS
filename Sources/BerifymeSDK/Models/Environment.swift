import Foundation

/// Berify.me environment configuration
public enum Environment: String, CaseIterable, Codable {
    case sandbox = "sandbox"
    case staging = "staging"
    case idv = "idv"
    
    /// Backend API domain
    public var backendDomain: String {
        switch self {
        case .sandbox:
            return "https://sandbox-backend.berify.me"
        case .staging:
            return "https://staging-backend.berify.me"
        case .idv:
            return "https://backend.berify.me"
        }
    }
    
    /// WebView domain
    public var webviewDomain: String {
        switch self {
        case .sandbox:
            return "https://sandbox.berify.me"
        case .staging:
            return "https://staging.berify.me"
        case .idv:
            return "https://idv.berify.me"
        }
    }
}
