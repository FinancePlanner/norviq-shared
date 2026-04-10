import Foundation

public struct AuthRegisterRequest: Codable, Sendable, Equatable {
    public let username: String
    public let password: String
    public let confirmPassword: String
    public let email: String
    public let dateOfBirth: Date

    public init(
        username: String,
        password: String,
        confirmPassword: String,
        email: String,
        dateOfBirth: Date
    ) {
        self.username = username
        self.password = password
        self.confirmPassword = confirmPassword
        self.email = email
        self.dateOfBirth = dateOfBirth
    }

    private enum CodingKeys: String, CodingKey {
        case username, password, confirmPassword, email, dateOfBirth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        confirmPassword = try container.decode(String.self, forKey: .confirmPassword)
        email = try container.decode(String.self, forKey: .email)
        dateOfBirth = try SharedDateDecoder.decodeDate(from: container, forKey: .dateOfBirth)
    }
}

public struct AuthLoginRequest: Codable, Sendable, Equatable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthResponse: Codable, Sendable, Equatable {
    public let token: String
    public let userId: UUID
    public let expiresIn: Int
    public let refreshToken: String
    public let refreshExpiresIn: Int
    public let username: String
    public let email: String
    public let dateOfBirth: Date

    public init(
        token: String,
        userId: UUID,
        expiresIn: Int,
        refreshToken: String,
        refreshExpiresIn: Int,
        username: String,
        email: String,
        dateOfBirth: Date
    ) {
        self.token = token
        self.userId = userId
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.refreshExpiresIn = refreshExpiresIn
        self.username = username
        self.email = email
        self.dateOfBirth = dateOfBirth
    }
}

/// Compatibility alias for endpoint layers that use API-style response names.
public typealias APIAuth = AuthResponse
public typealias AuthRegisterResponse = AuthResponse

public struct AuthUserResponse: Codable, Sendable, Equatable {
    public let id: String
    public let username: String
    public let email: String
    public let dateOfBirth: Date

    public init(
        id: String,
        username: String,
        email: String,
        dateOfBirth: Date
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.dateOfBirth = dateOfBirth
    }
}

public struct AuthForgotPasswordRequest: Codable, Sendable, Equatable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}

public struct AuthForgotPasswordResponse: Codable, Sendable, Equatable {
    public let message: String
    public let resetCode: String?

    public init(message: String, resetCode: String?) {
        self.message = message
        self.resetCode = resetCode
    }
}

public struct AuthResetPasswordRequest: Codable, Sendable, Equatable {
    public let email: String
    public let code: String
    public let newPassword: String

    public init(email: String, code: String, newPassword: String) {
        self.email = email
        self.code = code
        self.newPassword = newPassword
    }
}

public struct AuthRefreshRequest: Codable, Sendable, Equatable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public enum OAuthProvider: String, Codable, Sendable {
    case apple
    case google
    case x
}

public struct OAuthStartRequest: Codable, Sendable, Equatable {
    public let redirectURI: String

    public init(redirectURI: String) {
        self.redirectURI = redirectURI
    }
}

public struct OAuthStartResponse: Codable, Sendable, Equatable {
    public let flowId: UUID
    public let authorizationURL: String
    public let expiresIn: Int

    public init(flowId: UUID, authorizationURL: String, expiresIn: Int) {
        self.flowId = flowId
        self.authorizationURL = authorizationURL
        self.expiresIn = expiresIn
    }
}

public struct OAuthExchangeRequest: Codable, Sendable, Equatable {
    public let flowId: UUID
    public let code: String
    public let state: String
    public let redirectURI: String

    public init(flowId: UUID, code: String, state: String, redirectURI: String) {
        self.flowId = flowId
        self.code = code
        self.state = state
        self.redirectURI = redirectURI
    }
}
