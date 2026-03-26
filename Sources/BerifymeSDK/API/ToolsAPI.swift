import Foundation

/// Tools API
public class ToolsAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Create Session Token (no redirectUrl required)
    public func createSessionTokenWithoutRedirectUrl(
        apiKeyId: String,
        secretKey: String
    ) async throws -> CreateSessionTokenResponse {
        let endpoint = "/api/thirdParty/createTokenWithoutRedirectUrl"
        
        struct RequestBody: Codable {
            let apiKeyId: String
            let secretKey: String
        }
        
        let body = RequestBody(apiKeyId: apiKeyId, secretKey: secretKey)
        
        do {
            return try await client.post(
                endpoint: endpoint,
                body: body,
                responseType: CreateSessionTokenResponse.self
            )
        } catch {
            if case APIError.serverError(_, let message) = error {
                return CreateSessionTokenResponse(
                    sessionToken: nil,
                    companyLogo: nil,
                    error: message ?? "An error occurred, please try again"
                )
            }
            throw error
        }
    }
    
    /// Create Session Token (redirectUrl required)
    public func createSessionToken(
        apiKeyId: String,
        secretKey: String,
        redirectUrl: String
    ) async throws -> CreateSessionTokenResponse {
        let endpoint = "/api/thirdParty/createToken"
        
        struct RequestBody: Codable {
            let apiKeyId: String
            let secretKey: String
            let redirectUrl: String
        }
        
        let body = RequestBody(apiKeyId: apiKeyId, secretKey: secretKey, redirectUrl: redirectUrl)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: CreateSessionTokenResponse.self
        )
    }
    
    /// Get provider recommendation order by country code
    /// - Parameter countryCode: Country code (e.g. "US", "TW")
    /// - Returns: Provider order array (e.g. ["authid", "incode", "clear"]) or error message
    public func getOrderByCountry(countryCode: String) async throws -> GetOrderByCountryResponse {
        let endpoint = "/api/getOrderByCountry?code=\(countryCode)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetOrderByCountryResponse.self
        )
    }

    /// Align with RN: get generalVerificationToken (used after AllSet Continue)
    public func getGeneralVerificationToken(userId: String, token: String) async throws -> GetGeneralVerificationTokenResponse {
        let endpoint = "/api/thirdParty/getGeneralVerificationToken?userId=\(userId)"
        let headers = [
            "Content-Type": "application/json",
            "token": token
        ]
        return try await client.get(endpoint: endpoint, headers: headers, responseType: GetGeneralVerificationTokenResponse.self)
    }

    /// Check session token and get company configuration (e.g. useDefaultSuccessPageApp for result-page behavior).
    public func checkThirdPartyVerificationToken(token: String) async throws -> CheckTokenResponse {
        let endpoint = "/api/thirdParty/checkToken"
        let headers = [
            "Content-Type": "application/json",
            "token": token
        ]
        return try await client.get(endpoint: endpoint, headers: headers, responseType: CheckTokenResponse.self)
    }

    /// Get redirect URL (with token appended). For App use client=app so backend uses successRedirectUrlApp when default page is off.
    public func getRedirectUrl(userId: String, token: String, client: String = "app") async throws -> GetRedirectUrlResponse {
        var endpoint = "/api/thirdParty/getRedirectUrl?userId=\(userId)"
        if client == "app" {
            endpoint += "&client=app"
        }
        let headers = [
            "Content-Type": "application/json",
            "token": token
        ]
        return try await self.client.get(endpoint: endpoint, headers: headers, responseType: GetRedirectUrlResponse.self)
    }
}

/// Create Session Token response
public struct CreateSessionTokenResponse: Codable {
    public let sessionToken: String?
    public let companyLogo: String?
    public let error: String?
    
    public init(sessionToken: String? = nil, companyLogo: String? = nil, error: String? = nil) {
        self.sessionToken = sessionToken
        self.companyLogo = companyLogo
        self.error = error
    }
}

/// Get provider order by country response
public struct GetOrderByCountryResponse: Codable {
    public let order: [String]?
    public let error: String?
    
    public init(order: [String]? = nil, error: String? = nil) {
        self.order = order
        self.error = error
    }
}

public struct GetGeneralVerificationTokenResponse: Codable {
    public let generalVerificationToken: String?
    public let error: String?
    
    public init(generalVerificationToken: String? = nil, error: String? = nil) {
        self.generalVerificationToken = generalVerificationToken
        self.error = error
    }
}

/// Check token response (includes configuration for result-page settings).
public struct CheckTokenResponse: Codable {
    public let success: Bool?
    public let companyLogo: String?
    public let companyName: String?
    public let configuration: ResultPageConfiguration?
    public let error: String?

    public init(success: Bool? = nil, companyLogo: String? = nil, companyName: String? = nil, configuration: ResultPageConfiguration? = nil, error: String? = nil) {
        self.success = success
        self.companyLogo = companyLogo
        self.companyName = companyName
        self.configuration = configuration
        self.error = error
    }
}

public struct ResultPageConfiguration: Codable {
    public let useDefaultSuccessPageApp: Bool?
    public let useDefaultErrorPageApp: Bool?
    public let successRedirectUrlApp: String?
    public let errorRedirectUrlApp: String?
    /// ISO 3166-1 alpha-2 for default phone country (e.g. `"us"`, `"tw"`). Align with `checkToken` / WebSDK `defaultPhoneCountryCode`.
    public let defaultPhoneCountryCode: String?

    public init(
        useDefaultSuccessPageApp: Bool? = nil,
        useDefaultErrorPageApp: Bool? = nil,
        successRedirectUrlApp: String? = nil,
        errorRedirectUrlApp: String? = nil,
        defaultPhoneCountryCode: String? = nil
    ) {
        self.useDefaultSuccessPageApp = useDefaultSuccessPageApp
        self.useDefaultErrorPageApp = useDefaultErrorPageApp
        self.successRedirectUrlApp = successRedirectUrlApp
        self.errorRedirectUrlApp = errorRedirectUrlApp
        self.defaultPhoneCountryCode = defaultPhoneCountryCode
    }
}

public struct GetRedirectUrlResponse: Codable {
    public let redirectUrl: String?
    public let error: String?

    public init(redirectUrl: String? = nil, error: String? = nil) {
        self.redirectUrl = redirectUrl
        self.error = error
    }
}
