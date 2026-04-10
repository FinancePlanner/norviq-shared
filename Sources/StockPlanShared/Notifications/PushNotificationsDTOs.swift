import Foundation

public enum PushAuthorizationStatus: String, Codable, Sendable, Equatable, CaseIterable {
    case notDetermined
    case denied
    case authorized
    case provisional
}

public enum PushAPNSEnvironment: String, Codable, Sendable, Equatable, CaseIterable {
    case development
    case production
}

public enum PushPlatform: String, Codable, Sendable, Equatable, CaseIterable {
    case ios
}

public struct PushDeviceRegistrationRequest: Codable, Sendable, Equatable {
    public let deviceToken: String
    public let platform: PushPlatform
    public let apnsEnvironment: PushAPNSEnvironment
    public let authorizationStatus: PushAuthorizationStatus

    public init(
        deviceToken: String,
        platform: PushPlatform = .ios,
        apnsEnvironment: PushAPNSEnvironment,
        authorizationStatus: PushAuthorizationStatus
    ) {
        self.deviceToken = deviceToken
        self.platform = platform
        self.apnsEnvironment = apnsEnvironment
        self.authorizationStatus = authorizationStatus
    }
}

public struct PushDeviceRegistrationResponse: Codable, Sendable, Equatable {
    public let id: String
    public let deviceToken: String
    public let platform: PushPlatform
    public let apnsEnvironment: PushAPNSEnvironment
    public let authorizationStatus: PushAuthorizationStatus
    public let isActive: Bool
    public let lastSeenAt: String

    public init(
        id: String,
        deviceToken: String,
        platform: PushPlatform,
        apnsEnvironment: PushAPNSEnvironment,
        authorizationStatus: PushAuthorizationStatus,
        isActive: Bool,
        lastSeenAt: String
    ) {
        self.id = id
        self.deviceToken = deviceToken
        self.platform = platform
        self.apnsEnvironment = apnsEnvironment
        self.authorizationStatus = authorizationStatus
        self.isActive = isActive
        self.lastSeenAt = lastSeenAt
    }
}

public struct PushDeviceDeactivateRequest: Codable, Sendable, Equatable {
    public let deviceToken: String

    public init(deviceToken: String) {
        self.deviceToken = deviceToken
    }
}
