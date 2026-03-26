import Foundation

/// User data model
public struct User: Codable, Equatable {
    public let id: String
    public let isActive: Bool?
    public let email: String?
    public let phoneNumber: String?
    public let authIDAccountNumber: String?
    public let incodeId: String?
    public let clearId: String?
    public let sumsubId: String?
    public let veriffId: String?
    public let yotiId: String?
    public let idmeId: String?
    public let age: Int?
    public let birthDate: String?
    public let fullName: String?
    
    public init(
        id: String,
        isActive: Bool? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        authIDAccountNumber: String? = nil,
        incodeId: String? = nil,
        clearId: String? = nil,
        sumsubId: String? = nil,
        veriffId: String? = nil,
        yotiId: String? = nil,
        idmeId: String? = nil,
        age: Int? = nil,
        birthDate: String? = nil,
        fullName: String? = nil
    ) {
        self.id = id
        self.isActive = isActive
        self.email = email
        self.phoneNumber = phoneNumber
        self.authIDAccountNumber = authIDAccountNumber
        self.incodeId = incodeId
        self.clearId = clearId
        self.sumsubId = sumsubId
        self.veriffId = veriffId
        self.yotiId = yotiId
        self.idmeId = idmeId
        self.age = age
        self.birthDate = birthDate
        self.fullName = fullName
    }
}

/// Single credential (DB: id PK, userId, credentialID longblob, credentialPublicKey longblob, counter)
public struct Credential: Codable {
    public let id: String
    public let userId: String
    /// longblob; API may return base64 string or an object (e.g. WebAuthn-style), decode to Data when possible
    public let credentialID: Data?
    /// longblob; API typically returns base64 string, decode to Data
    public let credentialPublicKey: Data?
    public let counter: Int

    public init(
        id: String,
        userId: String,
        credentialID: Data? = nil,
        credentialPublicKey: Data? = nil,
        counter: Int
    ) {
        self.id = id
        self.userId = userId
        self.credentialID = credentialID
        self.credentialPublicKey = credentialPublicKey
        self.counter = counter
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        userId = try c.decode(String.self, forKey: .userId)
        counter = try c.decode(Int.self, forKey: .counter)
        credentialPublicKey = try? c.decodeIfPresent(Data.self, forKey: .credentialPublicKey)
        // credentialID: backend may send String (base64) or Dictionary (e.g. WebAuthn object)
        if let base64 = try? c.decodeIfPresent(String.self, forKey: .credentialID), let data = Data(base64Encoded: base64) {
            credentialID = data
        } else if c.contains(.credentialID) {
            _ = try? c.decodeIfPresent(JSONObject.self, forKey: .credentialID)
            credentialID = nil
        } else {
            credentialID = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(counter, forKey: .counter)
        try c.encodeIfPresent(credentialPublicKey, forKey: .credentialPublicKey)
        if let data = credentialID {
            try c.encode(data.base64EncodedString(), forKey: .credentialID)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, userId, credentialID, credentialPublicKey, counter
    }
}

/// Decode arbitrary JSON object (e.g. when credentialID is returned as an object)
private struct JSONObject: Decodable {
    init(from decoder: Decoder) throws {
        _ = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }
}

private enum JSONValue: Decodable {
    case string(String), int(Int), double(Double), bool(Bool)
    case array([JSONValue]), object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "null")) }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Int.self) { self = .int(v); return }
        if let v = try? c.decode(Double.self) { self = .double(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([JSONValue].self) { self = .array(v); return }
        if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unsupported"))
    }
}

/// User with credentials (inherits all User fields plus credentials)
public struct UserWithCredentials: Codable {
    // All User fields
    public let id: String
    public let isActive: Bool?
    public let email: String?
    public let phoneNumber: String?
    public let authIDAccountNumber: String?
    public let incodeId: String?
    public let clearId: String?
    public let sumsubId: String?
    public let veriffId: String?
    public let yotiId: String?
    public let idmeId: String?
    public let age: Int?
    public let birthDate: String?
    public let fullName: String?
    
    /// credentials is an array of Credential
    public let credentials: [Credential]?
    
    public init(
        id: String,
        isActive: Bool? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        authIDAccountNumber: String? = nil,
        incodeId: String? = nil,
        clearId: String? = nil,
        sumsubId: String? = nil,
        veriffId: String? = nil,
        yotiId: String? = nil,
        idmeId: String? = nil,
        age: Int? = nil,
        birthDate: String? = nil,
        fullName: String? = nil,
        credentials: [Credential]? = nil
    ) {
        self.id = id
        self.isActive = isActive
        self.email = email
        self.phoneNumber = phoneNumber
        self.authIDAccountNumber = authIDAccountNumber
        self.incodeId = incodeId
        self.clearId = clearId
        self.sumsubId = sumsubId
        self.veriffId = veriffId
        self.yotiId = yotiId
        self.idmeId = idmeId
        self.age = age
        self.birthDate = birthDate
        self.fullName = fullName
        self.credentials = credentials
    }
    
    // Convenience method to convert to User
    public var user: User {
        User(
            id: id,
            isActive: isActive,
            email: email,
            phoneNumber: phoneNumber,
            authIDAccountNumber: authIDAccountNumber,
            incodeId: incodeId,
            clearId: clearId,
            sumsubId: sumsubId,
            veriffId: veriffId,
            yotiId: yotiId,
            idmeId: idmeId,
            age: age,
            birthDate: birthDate,
            fullName: fullName
        )
    }
}

/// Device info
public struct Device: Codable {
    public let id: String
    public let userId: String
    public let deviceId: String
    public let createdAt: String  // String for API response compatibility
    public let expires: String    // String for API response compatibility
    
    public init(
        id: String,
        userId: String,
        deviceId: String,
        createdAt: String,
        expires: String
    ) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.createdAt = createdAt
        self.expires = expires
    }
}
