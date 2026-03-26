import Foundation

/// Wallet API
public class WalletAPI {
    private let client: APIClient
    
    public init(client: APIClient) {
        self.client = client
    }
    
    /// Get wallet info
    public func getWallet(
        phoneNumber: String
    ) async throws -> GetWalletResponse {
        let endpoint = "/api/wallet"
        
        struct RequestBody: Codable {
            let phoneNumber: String
        }
        
        let body = RequestBody(phoneNumber: phoneNumber)
        
        return try await client.post(
            endpoint: endpoint,
            body: body,
            responseType: GetWalletResponse.self
        )
    }
}

// MARK: - Response Models

public struct GetWalletResponse: Codable {
    // Adjust based on actual API response
    // Generic structure; may need more specific fields
    public let data: [String: AnyCodable]?
    public let error: String?
    
    public init(data: [String: AnyCodable]? = nil, error: String? = nil) {
        self.data = data
        self.error = error
    }
}

// Helper type for dynamic JSON
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}
