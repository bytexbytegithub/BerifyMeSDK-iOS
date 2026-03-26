import Foundation

/// Incode KYC API
public class IncodeAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Start Incode verification flow
    public func getIncodeStart(
        uniqueId: String? = nil
    ) async throws -> GetIncodeStartResponse {
        var endpoint = "/api/incode/start"
        if let uniqueId = uniqueId {
            endpoint += "?uniqueId=\(uniqueId)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetIncodeStartResponse.self
        )
    }
    
    /// Finish Incode verification flow
    public func getIncodeFinish(
        token: String
    ) async throws -> GetIncodeFinishResponse {
        let endpoint = "/api/incode/finish?token=\(token)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetIncodeFinishResponse.self
        )
    }
    
    /// Get Incode verification approval result
    public func getIncodeApprove(
        id: String,
        token: String,
        uniqueId: String
    ) async throws -> GetIncodeApproveResponse {
        let endpoint = "/api/incode/approve?id=\(id)&token=\(token)&uniqueId=\(uniqueId)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetIncodeApproveResponse.self
        )
    }
    
    /// Get App Incode verification approval result
    public func getAppIncodeApprove(
        id: String,
        incodeId: String
    ) async throws -> GetAppIncodeApproveResponse {
        let endpoint = "/api/incode/appApprove?id=\(id)&incodeId=\(incodeId)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetAppIncodeApproveResponse.self
        )
    }
}

// MARK: - Response Models

public struct GetIncodeStartResponse: Codable {
    public let token: String
    public let uniqueId: String
    
    public init(token: String, uniqueId: String) {
        self.token = token
        self.uniqueId = uniqueId
    }
}

public struct GetIncodeFinishResponse: Codable {
    public let token: String
    public let uniqueId: String
    
    public init(token: String, uniqueId: String) {
        self.token = token
        self.uniqueId = uniqueId
    }
}

public struct GetIncodeApproveResponse: Codable {
    public let incodeId: String?
    public let error: String?
    
    public init(incodeId: String? = nil, error: String? = nil) {
        self.incodeId = incodeId
        self.error = error
    }
}

public struct GetAppIncodeApproveResponse: Codable {
    public let incodeId: String?
    public let error: String?
    
    public init(incodeId: String? = nil, error: String? = nil) {
        self.incodeId = incodeId
        self.error = error
    }
}
