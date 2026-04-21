import Foundation

public struct BillingContextResponse: Codable, Sendable, Equatable {
    public let plan: String
    public let entitlementLevel: String
    public let isPremium: Bool
    public let subscription: BillingSubscriptionDTO?
    public let features: [BillingFeatureDTO]
    public let usage: [BillingUsageDTO]
    public let trialDaysRemaining: Int?
    public let isTrialActive: Bool
    public let generatedAt: Date

    public init(
        plan: String,
        entitlementLevel: String,
        isPremium: Bool,
        subscription: BillingSubscriptionDTO?,
        features: [BillingFeatureDTO],
        usage: [BillingUsageDTO],
        trialDaysRemaining: Int? = nil,
        isTrialActive: Bool = false,
        generatedAt: Date
    ) {
        self.plan = plan
        self.entitlementLevel = entitlementLevel
        self.isPremium = isPremium
        self.subscription = subscription
        self.features = features
        self.usage = usage
        self.trialDaysRemaining = trialDaysRemaining
        self.isTrialActive = isTrialActive
        self.generatedAt = generatedAt
    }
}

public struct BillingSubscriptionDTO: Codable, Sendable, Equatable {
    public let provider: String
    public let productId: String
    public let plan: String
    public let status: String
    public let periodStartedAt: Date?
    public let periodEndsAt: Date?
    public let trialEndsAt: Date?
    public let gracePeriodEndsAt: Date?
    public let cancelledAt: Date?
    public let isTrial: Bool
    public let isInGracePeriod: Bool
    public let hasBillingIssue: Bool
    public let isCancelledButActive: Bool
    public let renewsOrExpiresAt: Date?

    public init(
        provider: String,
        productId: String,
        plan: String,
        status: String,
        periodStartedAt: Date?,
        periodEndsAt: Date?,
        trialEndsAt: Date?,
        gracePeriodEndsAt: Date?,
        cancelledAt: Date?,
        isTrial: Bool,
        isInGracePeriod: Bool,
        hasBillingIssue: Bool,
        isCancelledButActive: Bool,
        renewsOrExpiresAt: Date?
    ) {
        self.provider = provider
        self.productId = productId
        self.plan = plan
        self.status = status
        self.periodStartedAt = periodStartedAt
        self.periodEndsAt = periodEndsAt
        self.trialEndsAt = trialEndsAt
        self.gracePeriodEndsAt = gracePeriodEndsAt
        self.cancelledAt = cancelledAt
        self.isTrial = isTrial
        self.isInGracePeriod = isInGracePeriod
        self.hasBillingIssue = hasBillingIssue
        self.isCancelledButActive = isCancelledButActive
        self.renewsOrExpiresAt = renewsOrExpiresAt
    }
}

public struct BillingFeatureDTO: Codable, Sendable, Equatable {
    public let key: String
    public let title: String
    public let available: Bool
    public let requiredPlan: String?
    public let reason: String?
    public let limit: Int?
    public let used: Int?
    public let remaining: Int?

    public init(
        key: String,
        title: String,
        available: Bool,
        requiredPlan: String?,
        reason: String?,
        limit: Int?,
        used: Int?,
        remaining: Int?
    ) {
        self.key = key
        self.title = title
        self.available = available
        self.requiredPlan = requiredPlan
        self.reason = reason
        self.limit = limit
        self.used = used
        self.remaining = remaining
    }
}

public struct BillingUsageDTO: Codable, Sendable, Equatable {
    public let key: String
    public let used: Int
    public let limit: Int?
    public let remaining: Int?
    public let periodStart: Date?

    public init(
        key: String,
        used: Int,
        limit: Int?,
        remaining: Int?,
        periodStart: Date?
    ) {
        self.key = key
        self.used = used
        self.limit = limit
        self.remaining = remaining
        self.periodStart = periodStart
    }
}

public struct BillingUpgradeRequiredResponse: Codable, Sendable, Equatable {
    public let success: Bool
    public let code: String
    public let error: String
    public let feature: String
    public let plan: String
    public let requiredPlan: String
    public let limit: Int?
    public let current: Int?

    public init(
        success: Bool,
        code: String,
        error: String,
        feature: String,
        plan: String,
        requiredPlan: String,
        limit: Int?,
        current: Int?
    ) {
        self.success = success
        self.code = code
        self.error = error
        self.feature = feature
        self.plan = plan
        self.requiredPlan = requiredPlan
        self.limit = limit
        self.current = current
    }
}
