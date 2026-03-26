import Foundation

/// Clear KYC API
public class ClearAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Create verification session
    public func createVerificationSession(
        redirectUrl: String,
        token: String? = nil
    ) async throws -> CreateVerificationSessionResponse {
        let endpoint = "https://backend.berify.me/api/clear/createVerificationSession"
        
        struct RequestBody: Codable {
            let redirectUrl: String
            let token: String?
        }
        
        let body = RequestBody(redirectUrl: redirectUrl, token: token)
        
        let tempClient = APIClient(baseURL: "")
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return try await tempClient.performRequest(request: request, responseType: CreateVerificationSessionResponse.self)
    }
    
    /// Get Clear verification approval result
    public func getClearApprove(
        id: String,
        sessionId: String,
        token: String? = nil
    ) async throws -> GetClearApproveResponse {
        var endpoint = "/api/clear/approve?id=\(id)&sessionId=\(sessionId)"
        if let token = token {
            endpoint += "&token=\(token)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetClearApproveResponse.self
        )
    }
}

// MARK: - Response Models

public struct CreateVerificationSessionResponse: Codable {
    public let sessionId: String
    public let token: String
    
    public init(sessionId: String, token: String) {
        self.sessionId = sessionId
        self.token = token
    }
}

public struct GetClearApproveResponse: Codable {
    public let clearId: String?
    public let error: String?
    
    public init(clearId: String? = nil, error: String? = nil) {
        self.clearId = clearId
        self.error = error
    }
}
