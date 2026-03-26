import Foundation

/// Auth API
public class AuthAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Send phone number verification code
    public func sendPhoneNumberCode(
        phoneNumber: String,
        token: String? = nil
    ) async throws -> SendPhoneNumberCodeResponse {
        var endpoint = "/api/auth/sendPhoneNumberCode?phoneNumber=\(phoneNumber)"
        if let token = token {
            endpoint += "&token=\(token)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: SendPhoneNumberCodeResponse.self
        )
    }
}

/// Send phone number verification code response
public struct SendPhoneNumberCodeResponse: Codable {
    public let success: Bool?
    public let error: String?
    
    public init(success: Bool? = nil, error: String? = nil) {
        self.success = success
        self.error = error
    }
}
