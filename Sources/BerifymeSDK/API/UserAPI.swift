import Foundation

/// User API
public class UserAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Get user by phone number and verification code
    public func getUserByPhoneNumberAndVerifyCode(
        phoneNumber: String,
        code: String
    ) async throws -> GetUserByPhoneNumberResponse {
        let endpoint = "/api/user/getUserByPhoneNumberAndVerifyCode?phoneNumber=\(phoneNumber)&code=\(code)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetUserByPhoneNumberResponse.self
        )
    }
    
    /// Get user's KYC provider by phone number
    public func getUserVenderByPhone(
        phoneNumber: String,
        token: String? = nil
    ) async throws -> GetUserVenderByPhoneResponse {
        var endpoint = "/api/user/getUserVenderByPhone?phoneNumber=\(phoneNumber)"
        if let token = token {
            endpoint += "&token=\(token)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetUserVenderByPhoneResponse.self
        )
    }
    
    /// Get user by Clear Session ID
    public func getUserBySessionId(
        sessionId: String,
        verificationStatus: VerificationStatus,
        token: String? = nil
    ) async throws -> GetUserBySessionIdResponse {
        var endpoint = "/api/user/getUserByClearSessionId?id=\(sessionId)&verificationStatus=\(verificationStatus.rawValue)"
        if let token = token {
            endpoint += "&token=\(token)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetUserBySessionIdResponse.self
        )
    }
    
    /// Get user by Incode ID
    public func getUserByIncodeId(
        incodeId: String
    ) async throws -> GetUserByIncodeIdResponse {
        let endpoint = "/api/user/getUserByIncodeId?incodeId=\(incodeId)"
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetUserByIncodeIdResponse.self
        )
    }
    
    /// Get user by Clear ID
    public func getUserByClearId(
        clearId: String,
        token: String? = nil
    ) async throws -> GetUserByClearIdResponse {
        var endpoint = "/api/user/getUserByClearId?clearId=\(clearId)"
        if let token = token {
            endpoint += "&token=\(token)"
        }
        
        return try await client.get(
            endpoint: endpoint,
            responseType: GetUserByClearIdResponse.self
        )
    }
    
    /// Upload device ID
    public func uploadDeviceId(
        id: String,
        deviceId: String,
        token: String? = nil
    ) async throws -> UploadDeviceIdResponse {
        let endpoint = "/api/user/uploadDeviceId"
        
        struct RequestBody: Codable {
            let id: String
            let deviceId: String
            let token: String?
        }
        
        let body = RequestBody(id: id, deviceId: deviceId, token: token)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: UploadDeviceIdResponse.self
        )
    }
    
    /// Check device ID
    public func checkDeviceId(
        phoneNumber: String,
        deviceId: String,
        token: String
    ) async throws -> CheckDeviceIdResponse {
        let endpoint = "/api/user/checkDeviceId"
        
        struct RequestBody: Codable {
            let phoneNumber: String
            let deviceId: String
            let token: String
        }
        
        let body = RequestBody(phoneNumber: phoneNumber, deviceId: deviceId, token: token)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: CheckDeviceIdResponse.self
        )
    }
    
    /// Create user by verified external phone number (requires session token for authorization; align with RN SDK)
    public func createUserByVerifiedExternalPhoneNumber(
        phoneNumber: String,
        token: String? = nil
    ) async throws -> CreateUserByVerifiedPhoneResponse {
        let endpoint = "/api/user/createUserByVerifiedExternalPhoneNumber"
        
        struct RequestBody: Codable {
            let phoneNumber: String
            let token: String?
        }
        
        let body = RequestBody(phoneNumber: phoneNumber, token: token)
        
        var headers: [String: String]? = nil
        if let token = token {
            headers = ["Authorization": "Bearer \(token)"]
        }
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            headers: headers,
            responseType: CreateUserByVerifiedPhoneResponse.self
        )
    }
}

// MARK: - Response Models

public struct GetUserByPhoneNumberResponse: Codable {
    public let user: UserWithCredentials?
    public let error: String?
    
    public init(user: UserWithCredentials? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}

public struct GetUserVenderByPhoneResponse: Codable {
    public let vender: String?
    public let fullName: String?
    public let error: String?
    
    public init(vender: String? = nil, fullName: String? = nil, error: String? = nil) {
        self.vender = vender
        self.fullName = fullName
        self.error = error
    }
}

public struct GetUserBySessionIdResponse: Codable {
    public let user: User?
    public let error: String?
    
    public init(user: User? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}

public struct GetUserByIncodeIdResponse: Codable {
    public let user: User?
    public let error: String?
    
    public init(user: User? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}

public struct GetUserByClearIdResponse: Codable {
    public let user: User?
    public let error: String?
    
    public init(user: User? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}

public struct UploadDeviceIdResponse: Codable {
    public let device: Device?
    public let error: String?
    
    public init(device: Device? = nil, error: String? = nil) {
        self.device = device
        self.error = error
    }
}

public struct CheckDeviceIdResponse: Codable {
    public let user: User?
    public let error: String?
    
    public init(user: User? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}

public struct CreateUserByVerifiedPhoneResponse: Codable {
    public let user: User?
    public let error: String?
    
    public init(user: User? = nil, error: String? = nil) {
        self.user = user
        self.error = error
    }
}
