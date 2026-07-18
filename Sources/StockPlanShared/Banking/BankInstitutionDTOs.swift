import Foundation

/// A selectable bank for the GoCardless hosted-link flow (EU). Plaid selects the
/// institution inside its own SDK, so this list is populated only for providers
/// that need the client to choose a bank first.
public struct BankInstitutionResponse: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let bic: String?
    public let logoURL: String?
    /// ISO 3166-1 alpha-2 country the institution belongs to.
    public let country: String?

    public init(id: String, name: String, bic: String? = nil, logoURL: String? = nil, country: String? = nil) {
        self.id = id
        self.name = name
        self.bic = bic
        self.logoURL = logoURL
        self.country = country
    }
}

/// Request to begin a GoCardless hosted link for a chosen institution.
public struct BankHostedLinkRequest: Codable, Sendable, Equatable {
    public let institutionId: String
    /// App/web URL GoCardless redirects back to after consent.
    public let redirectURI: String

    public init(institutionId: String, redirectURI: String) {
        self.institutionId = institutionId
        self.redirectURI = redirectURI
    }
}
