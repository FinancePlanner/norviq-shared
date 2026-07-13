import Foundation

public enum AIAssistantRole: String, Codable, Sendable { case user, assistant, tool }
public enum AIActionStatus: String, Codable, Sendable { case pending, confirmed, completed, cancelled, expired, failed }

public struct AIConversationSummaryResponse: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let lastMessagePreview: String?
    public let createdAt: String
    public let updatedAt: String
    public init(id: String, title: String, lastMessagePreview: String?, createdAt: String, updatedAt: String) {
        self.id = id; self.title = title; self.lastMessagePreview = lastMessagePreview
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct AIMessageResponse: Codable, Sendable, Equatable {
    public let id: String
    public let conversationId: String
    public let role: AIAssistantRole
    public let content: String
    public let createdAt: String
    public init(id: String, conversationId: String, role: AIAssistantRole, content: String, createdAt: String) {
        self.id = id; self.conversationId = conversationId; self.role = role
        self.content = content; self.createdAt = createdAt
    }
}

public struct AIConversationResponse: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let messages: [AIMessageResponse]
    public let createdAt: String
    public let updatedAt: String
    public init(id: String, title: String, messages: [AIMessageResponse], createdAt: String, updatedAt: String) {
        self.id = id; self.title = title; self.messages = messages
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct AIAssistantPreferencesResponse: Codable, Sendable, Equatable {
    public let proactiveTipsEnabled: Bool
    public let pushEnabled: Bool
    public let timezone: String
    public init(proactiveTipsEnabled: Bool, pushEnabled: Bool, timezone: String) {
        self.proactiveTipsEnabled = proactiveTipsEnabled; self.pushEnabled = pushEnabled; self.timezone = timezone
    }
}

public struct AIAssistantUsageResponse: Codable, Sendable, Equatable {
    public let month: String
    public let used: Int
    public let limit: Int?
    public let remaining: Int?
    public let isPro: Bool
    public init(month: String, used: Int, limit: Int?, remaining: Int?, isPro: Bool) {
        self.month = month; self.used = used; self.limit = limit; self.remaining = remaining; self.isPro = isPro
    }
}

public struct AITipResponse: Codable, Sendable, Equatable {
    public let id: String
    public let kind: String
    public let title: String
    public let body: String
    public let importance: Int
    public let actionPath: String?
    public let createdAt: String
    public let expiresAt: String
    public init(id: String, kind: String, title: String, body: String, importance: Int, actionPath: String?, createdAt: String, expiresAt: String) {
        self.id = id; self.kind = kind; self.title = title; self.body = body; self.importance = importance
        self.actionPath = actionPath; self.createdAt = createdAt; self.expiresAt = expiresAt
    }
}

public struct AIPendingActionResponse: Codable, Sendable, Equatable {
    public let id: String
    public let conversationId: String?
    public let toolName: String
    public let summary: String
    public let arguments: String
    public let status: AIActionStatus
    public let expiresAt: String
    public let createdAt: String
    public init(id: String, conversationId: String?, toolName: String, summary: String, arguments: String, status: AIActionStatus, expiresAt: String, createdAt: String) {
        self.id = id; self.conversationId = conversationId; self.toolName = toolName
        self.summary = summary; self.arguments = arguments; self.status = status
        self.expiresAt = expiresAt; self.createdAt = createdAt
    }
}
