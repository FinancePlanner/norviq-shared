import Foundation

public struct BrokerConnectionResponse: Codable, Sendable, Equatable {
    public let id: String
    public let provider: String
    public let status: String

    public init(id: String, provider: String, status: String) {
        self.id = id
        self.provider = provider
        self.status = status
    }
}

public struct BrokerHoldingResponse: Codable, Sendable, Equatable {
    public let symbol: String
    public let quantity: Double
    public let currency: String

    public init(symbol: String, quantity: Double, currency: String) {
        self.symbol = symbol
        self.quantity = quantity
        self.currency = currency
    }
}

public struct BrokerSyncResponse: Codable, Sendable, Equatable {
    public let runId: String
    public let status: String

    public init(runId: String, status: String) {
        self.runId = runId
        self.status = status
    }
}
