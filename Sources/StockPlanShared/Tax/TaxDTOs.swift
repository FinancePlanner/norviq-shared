import Foundation

public enum TaxJurisdiction: String, Codable, Sendable, CaseIterable {
    case unitedStates = "US"
    case portugal = "PT"
    case spain = "ES"
    case germany = "DE"
    case france = "FR"
    case italy = "IT"
}

public enum TaxFilingStatus: String, Codable, Sendable, CaseIterable {
    case single
    case marriedJoint = "married_joint"
    case marriedSeparate = "married_separate"
    case domesticPartnership = "domestic_partnership"
}

/// Selects how securities capital gains are taxed when a jurisdiction permits an election.
/// A nil value on TaxProfileRequest preserves the jurisdiction default for profiles written
/// by older clients.
public enum TaxCapitalGainsTaxationMode: String, Codable, Sendable, CaseIterable {
    case jurisdictionDefault = "jurisdiction_default"
    case autonomous
    case aggregateWithIncome = "aggregate_with_income"
}

public enum TaxAccountWrapper: String, Codable, Sendable, CaseIterable {
    case taxable
    case traditionalIRA = "traditional_ira"
    case rothIRA = "roth_ira"
    case pension
    case taxExempt = "tax_exempt"
    case countrySpecific = "country_specific"
    case unknown
}

public enum TaxLotSelectionMethod: String, Codable, Sendable, CaseIterable {
    case fifo
    case lifo
    case specificID = "specific_id"
    case jurisdictionDefault = "jurisdiction_default"
}

public enum TaxSupportLevel: String, Codable, Sendable {
    case supported
    case estimateOnly = "estimate_only"
    case professionalReview = "professional_review"
    case unsupported
}

public struct TaxRuleCapability: Codable, Sendable, Equatable, Identifiable {
    public var id: String { "\(jurisdiction.rawValue):\(taxYear):\(instrumentType)" }
    public let jurisdiction: TaxJurisdiction
    public let taxYear: Int
    public let ruleVersion: String
    public let instrumentType: String
    public let supportLevel: TaxSupportLevel
    public let supportedAccountWrappers: [TaxAccountWrapper]
    public let limitations: [String]

    public init(
        jurisdiction: TaxJurisdiction,
        taxYear: Int,
        ruleVersion: String,
        instrumentType: String,
        supportLevel: TaxSupportLevel,
        supportedAccountWrappers: [TaxAccountWrapper],
        limitations: [String] = []
    ) {
        self.jurisdiction = jurisdiction
        self.taxYear = taxYear
        self.ruleVersion = ruleVersion
        self.instrumentType = instrumentType
        self.supportLevel = supportLevel
        self.supportedAccountWrappers = supportedAccountWrappers
        self.limitations = limitations
    }
}

public struct TaxCapabilitiesResponse: Codable, Sendable, Equatable {
    public let generatedAt: String
    public let capabilities: [TaxRuleCapability]

    public init(generatedAt: String, capabilities: [TaxRuleCapability]) {
        self.generatedAt = generatedAt
        self.capabilities = capabilities
    }
}

public struct TaxHouseholdMember: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let relationship: String

    public init(id: String, displayName: String, relationship: String) {
        self.id = id
        self.displayName = displayName
        self.relationship = relationship
    }
}

public struct TaxAccountClassification: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let accountId: String
    public let ownerMemberId: String
    public let wrapper: TaxAccountWrapper
    public let countryWrapperCode: String?
    public let lotSelectionMethod: TaxLotSelectionMethod

    public init(
        id: String,
        accountId: String,
        ownerMemberId: String,
        wrapper: TaxAccountWrapper,
        countryWrapperCode: String? = nil,
        lotSelectionMethod: TaxLotSelectionMethod = .jurisdictionDefault
    ) {
        self.id = id
        self.accountId = accountId
        self.ownerMemberId = ownerMemberId
        self.wrapper = wrapper
        self.countryWrapperCode = countryWrapperCode
        self.lotSelectionMethod = lotSelectionMethod
    }
}

public struct TaxProfileRequest: Codable, Sendable, Equatable {
    public let jurisdiction: TaxJurisdiction
    public let taxYear: Int
    public let filingStatus: TaxFilingStatus
    public let reportingCurrency: String
    public let estimatedTaxableIncome: Decimal
    public let marginalIncomeTaxRate: Decimal?
    public let shortTermCapitalGainsRate: Decimal?
    public let longTermCapitalGainsRate: Decimal?
    public let capitalGainsTaxationMode: TaxCapitalGainsTaxationMode?
    public let remainingCapitalIncomeAllowance: Decimal?
    public let churchTaxRate: Decimal?
    public let priorShortTermLossCarryover: Decimal
    public let priorLongTermLossCarryover: Decimal
    public let members: [TaxHouseholdMember]
    public let accounts: [TaxAccountClassification]

    public init(
        jurisdiction: TaxJurisdiction,
        taxYear: Int,
        filingStatus: TaxFilingStatus,
        reportingCurrency: String,
        estimatedTaxableIncome: Decimal,
        marginalIncomeTaxRate: Decimal? = nil,
        shortTermCapitalGainsRate: Decimal? = nil,
        longTermCapitalGainsRate: Decimal? = nil,
        capitalGainsTaxationMode: TaxCapitalGainsTaxationMode? = nil,
        remainingCapitalIncomeAllowance: Decimal? = nil,
        churchTaxRate: Decimal? = nil,
        priorShortTermLossCarryover: Decimal = 0,
        priorLongTermLossCarryover: Decimal = 0,
        members: [TaxHouseholdMember],
        accounts: [TaxAccountClassification]
    ) {
        self.jurisdiction = jurisdiction
        self.taxYear = taxYear
        self.filingStatus = filingStatus
        self.reportingCurrency = reportingCurrency
        self.estimatedTaxableIncome = estimatedTaxableIncome
        self.marginalIncomeTaxRate = marginalIncomeTaxRate
        self.shortTermCapitalGainsRate = shortTermCapitalGainsRate
        self.longTermCapitalGainsRate = longTermCapitalGainsRate
        self.capitalGainsTaxationMode = capitalGainsTaxationMode
        self.remainingCapitalIncomeAllowance = remainingCapitalIncomeAllowance
        self.churchTaxRate = churchTaxRate
        self.priorShortTermLossCarryover = priorShortTermLossCarryover
        self.priorLongTermLossCarryover = priorLongTermLossCarryover
        self.members = members
        self.accounts = accounts
    }
}

public struct TaxProfileResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let profile: TaxProfileRequest
    public let isComplete: Bool
    public let missingFields: [String]
    public let updatedAt: String

    public init(id: String, profile: TaxProfileRequest, isComplete: Bool, missingFields: [String], updatedAt: String) {
        self.id = id
        self.profile = profile
        self.isComplete = isComplete
        self.missingFields = missingFields
        self.updatedAt = updatedAt
    }
}

public struct TaxProfileAccountOption: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let broker: String
    public let baseCurrency: String
    public let wrapper: TaxAccountWrapper
    public let ownerMemberId: String?
    public let lotSelectionMethod: TaxLotSelectionMethod

    public init(
        id: String,
        displayName: String,
        broker: String,
        baseCurrency: String,
        wrapper: TaxAccountWrapper = .unknown,
        ownerMemberId: String? = nil,
        lotSelectionMethod: TaxLotSelectionMethod = .jurisdictionDefault
    ) {
        self.id = id
        self.displayName = displayName
        self.broker = broker
        self.baseCurrency = baseCurrency
        self.wrapper = wrapper
        self.ownerMemberId = ownerMemberId
        self.lotSelectionMethod = lotSelectionMethod
    }
}

public enum TaxMarketAdmissionStatus: String, Codable, Sendable, CaseIterable {
    case regulated
    case unlisted
    case unknown
}

public enum TaxFundClassification: String, Codable, Sendable, CaseIterable {
    case equity
    case mixed
    case realEstate = "real_estate"
    case foreignRealEstate = "foreign_real_estate"
    case other
    case unknown
}

public struct TaxFundClassificationRequest: Codable, Sendable, Equatable {
    public let classification: TaxFundClassification

    public init(classification: TaxFundClassification) {
        self.classification = classification
    }
}

public struct TaxInstrumentMarketOption: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let symbol: String
    public let listingExchange: String?
    public let marketAdmissionStatus: TaxMarketAdmissionStatus
    public let fundClassification: TaxFundClassification?

    public init(
        id: String,
        symbol: String,
        listingExchange: String? = nil,
        marketAdmissionStatus: TaxMarketAdmissionStatus = .unknown,
        fundClassification: TaxFundClassification? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.listingExchange = listingExchange
        self.marketAdmissionStatus = marketAdmissionStatus
        self.fundClassification = fundClassification
    }
}

public struct TaxProfileContextResponse: Codable, Sendable, Equatable {
    public let jurisdiction: TaxJurisdiction
    public let taxYear: Int
    public let defaultReportingCurrency: String
    public let profile: TaxProfileResponse?
    public let accounts: [TaxProfileAccountOption]
    public let instruments: [TaxInstrumentMarketOption]?

    public init(
        jurisdiction: TaxJurisdiction,
        taxYear: Int,
        defaultReportingCurrency: String,
        profile: TaxProfileResponse? = nil,
        accounts: [TaxProfileAccountOption],
        instruments: [TaxInstrumentMarketOption]? = nil
    ) {
        self.jurisdiction = jurisdiction
        self.taxYear = taxYear
        self.defaultReportingCurrency = defaultReportingCurrency
        self.profile = profile
        self.accounts = accounts
        self.instruments = instruments
    }
}

public struct TaxMoney: Codable, Sendable, Equatable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

public struct TaxLossCarryforwardApplicationResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let targetTaxYear: Int
    public let amount: TaxMoney
    public let createdAt: String

    public init(id: String, targetTaxYear: Int, amount: TaxMoney, createdAt: String) {
        self.id = id
        self.targetTaxYear = targetTaxYear
        self.amount = amount
        self.createdAt = createdAt
    }
}

public struct TaxLossCarryforwardBalanceResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let jurisdiction: TaxJurisdiction
    public let sourceTaxYear: Int
    public let expiresAfterTaxYear: Int
    public let originalAmount: TaxMoney
    public let remainingAmount: TaxMoney
    public let ruleVersion: String
    public let applications: [TaxLossCarryforwardApplicationResponse]

    public init(
        id: String,
        jurisdiction: TaxJurisdiction,
        sourceTaxYear: Int,
        expiresAfterTaxYear: Int,
        originalAmount: TaxMoney,
        remainingAmount: TaxMoney,
        ruleVersion: String,
        applications: [TaxLossCarryforwardApplicationResponse]
    ) {
        self.id = id
        self.jurisdiction = jurisdiction
        self.sourceTaxYear = sourceTaxYear
        self.expiresAfterTaxYear = expiresAfterTaxYear
        self.originalAmount = originalAmount
        self.remainingAmount = remainingAmount
        self.ruleVersion = ruleVersion
        self.applications = applications
    }
}

public struct TaxLossCarryforwardLedgerResponse: Codable, Sendable, Equatable {
    public let generatedAt: String
    public let jurisdiction: TaxJurisdiction
    public let asOfTaxYear: Int
    public let totalAvailable: TaxMoney
    public let balances: [TaxLossCarryforwardBalanceResponse]

    public init(
        generatedAt: String,
        jurisdiction: TaxJurisdiction,
        asOfTaxYear: Int,
        totalAvailable: TaxMoney,
        balances: [TaxLossCarryforwardBalanceResponse]
    ) {
        self.generatedAt = generatedAt
        self.jurisdiction = jurisdiction
        self.asOfTaxYear = asOfTaxYear
        self.totalAvailable = totalAvailable
        self.balances = balances
    }
}

public struct TaxProjectionSummary: Codable, Sendable, Equatable {
    public let realizedEstimatedLiability: TaxMoney
    public let embeddedUnrealizedLiability: TaxMoney
    public let harvestableLosses: TaxMoney
    public let estimatedNetBenefit: TaxMoney
    public let shortTermCarryover: TaxMoney
    public let longTermCarryover: TaxMoney
    public let taxCostRatio: Decimal?

    public init(
        realizedEstimatedLiability: TaxMoney,
        embeddedUnrealizedLiability: TaxMoney,
        harvestableLosses: TaxMoney,
        estimatedNetBenefit: TaxMoney,
        shortTermCarryover: TaxMoney,
        longTermCarryover: TaxMoney,
        taxCostRatio: Decimal?
    ) {
        self.realizedEstimatedLiability = realizedEstimatedLiability
        self.embeddedUnrealizedLiability = embeddedUnrealizedLiability
        self.harvestableLosses = harvestableLosses
        self.estimatedNetBenefit = estimatedNetBenefit
        self.shortTermCarryover = shortTermCarryover
        self.longTermCarryover = longTermCarryover
        self.taxCostRatio = taxCostRatio
    }
}

public enum TaxOpportunityStatus: String, Codable, Sendable {
    case actionable
    case watch
    case blocked
    case accepted
    case dismissed
}

public struct TaxOpportunityResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let accountId: String
    public let instrumentId: String
    public let symbol: String
    public let instrumentType: String
    public let status: TaxOpportunityStatus
    public let supportLevel: TaxSupportLevel
    public let marketValue: TaxMoney
    public let unrealizedLoss: TaxMoney
    public let estimatedTaxBenefit: TaxMoney
    public let eligibleQuantity: Decimal
    public let holdingPeriod: String
    public let washSaleWindowEndsAt: String?
    public let warnings: [String]
    public let confidence: Decimal

    public init(
        id: String,
        accountId: String,
        instrumentId: String,
        symbol: String,
        instrumentType: String,
        status: TaxOpportunityStatus,
        supportLevel: TaxSupportLevel,
        marketValue: TaxMoney,
        unrealizedLoss: TaxMoney,
        estimatedTaxBenefit: TaxMoney,
        eligibleQuantity: Decimal,
        holdingPeriod: String,
        washSaleWindowEndsAt: String? = nil,
        warnings: [String] = [],
        confidence: Decimal
    ) {
        self.id = id
        self.accountId = accountId
        self.instrumentId = instrumentId
        self.symbol = symbol
        self.instrumentType = instrumentType
        self.status = status
        self.supportLevel = supportLevel
        self.marketValue = marketValue
        self.unrealizedLoss = unrealizedLoss
        self.estimatedTaxBenefit = estimatedTaxBenefit
        self.eligibleQuantity = eligibleQuantity
        self.holdingPeriod = holdingPeriod
        self.washSaleWindowEndsAt = washSaleWindowEndsAt
        self.warnings = warnings
        self.confidence = confidence
    }
}

public struct TaxDashboardResponse: Codable, Sendable, Equatable {
    public let generatedAt: String
    public let taxYear: Int
    public let jurisdiction: TaxJurisdiction
    public let ruleVersion: String
    public let isStale: Bool
    public let profileComplete: Bool
    public let summary: TaxProjectionSummary
    public let opportunities: [TaxOpportunityResponse]
    public let unsupportedValue: TaxMoney
    public let assumptions: [String]
    public let disclaimer: String

    public init(
        generatedAt: String,
        taxYear: Int,
        jurisdiction: TaxJurisdiction,
        ruleVersion: String,
        isStale: Bool,
        profileComplete: Bool,
        summary: TaxProjectionSummary,
        opportunities: [TaxOpportunityResponse],
        unsupportedValue: TaxMoney,
        assumptions: [String],
        disclaimer: String
    ) {
        self.generatedAt = generatedAt
        self.taxYear = taxYear
        self.jurisdiction = jurisdiction
        self.ruleVersion = ruleVersion
        self.isStale = isStale
        self.profileComplete = profileComplete
        self.summary = summary
        self.opportunities = opportunities
        self.unsupportedValue = unsupportedValue
        self.assumptions = assumptions
        self.disclaimer = disclaimer
    }
}

public struct TaxScenarioRequest: Codable, Sendable, Equatable {
    public let taxYear: Int
    public let opportunityIds: [String]
    public let plannedReplacementInstrumentIds: [String: String]

    public init(
        taxYear: Int,
        opportunityIds: [String],
        plannedReplacementInstrumentIds: [String: String] = [:]
    ) {
        self.taxYear = taxYear
        self.opportunityIds = opportunityIds
        self.plannedReplacementInstrumentIds = plannedReplacementInstrumentIds
    }
}

public struct TaxScenarioColumn: Codable, Sendable, Equatable {
    public let currentYearTax: TaxMoney
    public let nextYearTax: TaxMoney
    public let realizedLosses: TaxMoney
    public let carryover: TaxMoney
    public let feesAndSpread: TaxMoney

    public init(
        currentYearTax: TaxMoney,
        nextYearTax: TaxMoney,
        realizedLosses: TaxMoney,
        carryover: TaxMoney,
        feesAndSpread: TaxMoney
    ) {
        self.currentYearTax = currentYearTax
        self.nextYearTax = nextYearTax
        self.realizedLosses = realizedLosses
        self.carryover = carryover
        self.feesAndSpread = feesAndSpread
    }
}

public struct TaxScenarioResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let createdAt: String
    public let baseline: TaxScenarioColumn
    public let harvestNow: TaxScenarioColumn
    public let estimatedNetBenefit: TaxMoney
    public let warnings: [String]
    public let assumptions: [String]

    public init(
        id: String,
        createdAt: String,
        baseline: TaxScenarioColumn,
        harvestNow: TaxScenarioColumn,
        estimatedNetBenefit: TaxMoney,
        warnings: [String],
        assumptions: [String]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.baseline = baseline
        self.harvestNow = harvestNow
        self.estimatedNetBenefit = estimatedNetBenefit
        self.warnings = warnings
        self.assumptions = assumptions
    }
}

public struct TaxActionPlanRequest: Codable, Sendable, Equatable {
    public let scenarioId: String
    public let idempotencyKey: String

    public init(scenarioId: String, idempotencyKey: String) {
        self.scenarioId = scenarioId
        self.idempotencyKey = idempotencyKey
    }
}

public struct TaxActionStep: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let order: Int
    public let title: String
    public let detail: String
    public let earliestDate: String?
    public let completed: Bool

    public init(id: String, order: Int, title: String, detail: String, earliestDate: String? = nil, completed: Bool) {
        self.id = id
        self.order = order
        self.title = title
        self.detail = detail
        self.earliestDate = earliestDate
        self.completed = completed
    }
}

public struct TaxActionPlanResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let scenarioId: String
    public let status: String
    public let createdAt: String
    public let steps: [TaxActionStep]
    public let disclaimer: String

    public init(id: String, scenarioId: String, status: String, createdAt: String, steps: [TaxActionStep], disclaimer: String) {
        self.id = id
        self.scenarioId = scenarioId
        self.status = status
        self.createdAt = createdAt
        self.steps = steps
        self.disclaimer = disclaimer
    }
}

public enum TaxReportKind: String, Codable, Sendable, CaseIterable {
    case transactionWorkpaper = "transaction_workpaper"
    case form8949 = "form_8949"
    case scheduleDSummary = "schedule_d_summary"
    case countryCapitalGains = "country_capital_gains"
}

public enum TaxReportFormat: String, Codable, Sendable, CaseIterable {
    case csv
    case pdf
}

public struct TaxReportRequest: Codable, Sendable, Equatable {
    public let taxYear: Int
    public let kind: TaxReportKind
    public let format: TaxReportFormat

    public init(taxYear: Int, kind: TaxReportKind, format: TaxReportFormat) {
        self.taxYear = taxYear
        self.kind = kind
        self.format = format
    }
}

public struct TaxReportResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let taxYear: Int
    public let kind: TaxReportKind
    public let format: TaxReportFormat
    public let status: String
    public let createdAt: String
    public let expiresAt: String?
    public let downloadPath: String?

    public init(
        id: String,
        taxYear: Int,
        kind: TaxReportKind,
        format: TaxReportFormat,
        status: String,
        createdAt: String,
        expiresAt: String? = nil,
        downloadPath: String? = nil
    ) {
        self.id = id
        self.taxYear = taxYear
        self.kind = kind
        self.format = format
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.downloadPath = downloadPath
    }
}

public struct TaxNotificationPreferences: Codable, Sendable, Equatable {
    public let enabled: Bool
    public let minimumBenefit: Decimal?
    public let cooldownDays: Int

    public init(enabled: Bool, minimumBenefit: Decimal? = nil, cooldownDays: Int = 7) {
        self.enabled = enabled
        self.minimumBenefit = minimumBenefit
        self.cooldownDays = cooldownDays
    }
}
