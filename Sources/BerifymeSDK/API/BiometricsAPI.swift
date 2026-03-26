import Foundation

/// Biometrics API
public class BiometricsAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Check biometrics status
    public func checkBiometricsStatus(
        phoneNumber: String,
        publicKey: String?
    ) async throws -> CheckBiometricsStatusResponse {
        let endpoint = "/api/biometrics/checkBiometricsStatus"
        
        struct RequestBody: Codable {
            let phoneNumber: String
            let publicKey: String?
        }
        
        let body = RequestBody(phoneNumber: phoneNumber, publicKey: publicKey)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: CheckBiometricsStatusResponse.self
        )
    }
    
    /// Create biometrics
    public func createBiometrics(
        phoneNumber: String,
        publicKey: String?,
        signature: String
    ) async throws -> CreateBiometricsResponse {
        let endpoint = "/api/biometrics/createBiometrics"
        
        struct RequestBody: Codable {
            let phoneNumber: String
            let publicKey: String?
            let signature: String
        }
        
        let body = RequestBody(phoneNumber: phoneNumber, publicKey: publicKey, signature: signature)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: CreateBiometricsResponse.self
        )
    }
    
    /// Delete biometrics
    public func deleteBiometrics(
        phoneNumber: String
    ) async throws -> DeleteBiometricsResponse {
        let endpoint = "/api/biometrics/deleteBiometrics"
        
        struct RequestBody: Codable {
            let phoneNumber: String
        }
        
        let body = RequestBody(phoneNumber: phoneNumber)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: DeleteBiometricsResponse.self
        )
    }
}

// MARK: - Response Models

/// Biometrics status
public enum BiometricsStatus: String, Codable {
    case notSet = "NotSet"
    case match = "Match"
    case notMatch = "NotMatch"
}

public struct CheckBiometricsStatusResponse: Codable {
    public let status: BiometricsStatus?
    public let exists: Bool?
    public let isExist: Bool?
    public let user: User?
    public let error: String?
    
    public init(status: BiometricsStatus? = nil, exists: Bool? = nil, isExist: Bool? = nil, user: User? = nil, error: String? = nil) {
        self.status = status
        self.exists = exists
        self.isExist = isExist
        self.user = user
        self.error = error
    }
    
    public var isSet: Bool {
        if let status = status {
            return status == .match
        }
        return exists == true || isExist == true
    }
}

public struct CreateBiometricsResponse: Codable {
    public let success: Bool?
    public let error: String?
    
    public init(success: Bool? = nil, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

public struct DeleteBiometricsResponse: Codable {
    public let success: Bool?
    public let error: String?
    
    public init(success: Bool? = nil, error: String? = nil) {
        self.success = success
        self.error = error
    }
}
