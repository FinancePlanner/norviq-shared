import Foundation
import Testing

@testable import StockPlanShared

@Test func authLoginRequestRoundTripJSON() throws {
    let payload = AuthLoginRequest(email: "user@example.com", password: "secret")

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(AuthLoginRequest.self, from: encoded)

    #expect(decoded == payload)
}

@Test func authRegisterRequestRoundTripJSON() throws {
    let payload = AuthRegisterRequest(
        username: "valid_user",
        password: "Password123",
        email: "user@example.com",
        dateOfBirth: Date(timeIntervalSince1970: 946_684_800)
    )

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(AuthRegisterRequest.self, from: encoded)

    #expect(decoded == payload)
}

@Test func stockResponseRoundTripJSON() throws {
    let payload = StockResponse(
        id: "stock-id",
        symbol: "AAPL",
        shares: 10,
        buyPrice: 150.25,
        buyDate: "2026-01-10",
        notes: "Starter position"
    )

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(StockResponse.self, from: encoded)

    #expect(decoded == payload)
}

@Test func goalStatusUpdateRequestRoundTripJSON() throws {
    let payload = GoalStatusUpdateRequest(status: .completed, source: .manual)

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(GoalStatusUpdateRequest.self, from: encoded)

    #expect(decoded == payload)
}

@Test func goalResponseRoundTripJSON() throws {
    let payload = GoalResponse(
        id: "goal-id",
        title: "Review watchlist before earnings",
        status: .pending,
        statusUpdatedBy: .manual,
        completedAt: nil,
        createdAt: "2026-04-08T10:00:00Z",
        updatedAt: "2026-04-08T10:00:00Z"
    )

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(GoalResponse.self, from: encoded)

    #expect(decoded == payload)
}

@Test func apiSuccessRoundTripJSON() throws {
    let payload = APISuccess(success: true)

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(APISuccess.self, from: encoded)

    #expect(decoded == payload)
}

@Test func apiEnvelopeRoundTripJSON() throws {
    let auth = AuthResponse(
        token: "jwt-token",
        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        expiresIn: 604800,
        refreshToken: "refresh-token",
        refreshExpiresIn: 2_592_000,
        username: "valid_user",
        email: "user@example.com",
        dateOfBirth: Date(timeIntervalSince1970: 946_684_800)
    )

    let payload = APIEnvelope(success: true, data: auth, message: "ok")

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(APIEnvelope<AuthResponse>.self, from: encoded)

    #expect(decoded == payload)
}

@Test func stockPlanSharedDecoderDecodesAuthResponseEncodedAsReferenceDateNumber() throws {
    let payload = AuthResponse(
        token: "jwt-token",
        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        expiresIn: 604800,
        refreshToken: "refresh-token",
        refreshExpiresIn: 2_592_000,
        username: "valid_user",
        email: "user@example.com",
        dateOfBirth: Date(timeIntervalSince1970: 946_684_800)
    )

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder.stockPlanShared.decode(AuthResponse.self, from: encoded)

    #expect(decoded == payload)
}

@Test func stockPlanSharedDecoderDecodesSnakeCaseDBStyleDateString() throws {
    let payload = """
    {
      "token": "jwt-token",
      "user_id": "00000000-0000-0000-0000-000000000001",
      "expires_in": 604800,
      "refresh_token": "refresh-token",
      "refresh_expires_in": 2592000,
      "username": "valid_user",
      "email": "user@example.com",
      "date_of_birth": "2000-01-01"
    }
    """.data(using: .utf8)!

    let decoded = try JSONDecoder.stockPlanShared.decode(AuthResponse.self, from: payload)

    #expect(decoded.userId == UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    #expect(decoded.dateOfBirth == DateFormatter.yyyyMMdd.date(from: "2000-01-01"))
}

@Test func bulkStockRequestRoundTripJSON() throws {
    let payload = BulkStockRequest(stocks: [
        StockRequest(
            symbol: "AAPL", shares: 10.5, buyPrice: 150.25, buyDate: "2026-01-10", notes: "First"),
        StockRequest(
            symbol: "MSFT", shares: 5, buyPrice: 300.00, buyDate: "2026-02-15", notes: nil),
    ])

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(BulkStockRequest.self, from: encoded)

    #expect(decoded == payload)
}

@Test func bulkStockResponseRoundTripJSON() throws {
    let payload = BulkStockResponse(
        created: 1,
        failed: 1,
        results: [
            BulkStockResultItem(
                index: 0,
                stock: StockResponse(
                    id: "id-1", symbol: "AAPL", shares: 10.5, buyPrice: 150.25,
                    buyDate: "2026-01-10", notes: nil)
            ),
            BulkStockResultItem(index: 1, error: "Invalid buyDate. Expected YYYY-MM-DD."),
        ]
    )

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(BulkStockResponse.self, from: encoded)

    #expect(decoded == payload)
}

@Test func bulkStockRequestEmptyArray() throws {
    let payload = BulkStockRequest(stocks: [])

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(BulkStockRequest.self, from: encoded)

    #expect(decoded == payload)
    #expect(decoded.stocks.isEmpty)
}

@Test func userProfileResponseRoundTripJSON() throws {
    let profile = UserProfile(
        id: "user-id",
        email: "user@example.com",
        bio: "Investor",
        avatarURL: URL(string: "https://example.com/avatar.png"),
        bannerAvatarURL: URL(string: "https://example.com/banner.png"),
        username: "investor_1"
    )
    let payload = GetUserProfileResponse(userProfile: profile)

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(GetUserProfileResponse.self, from: encoded)

    #expect(decoded == payload)
}

@Test func updateUserProfileRequestRoundTripJSON() throws {
    let profile = UserProfile(
        id: "user-id",
        email: "user@example.com",
        bio: "Long-term investor",
        avatarURL: nil,
        bannerAvatarURL: nil,
        username: "valueinvestor"
    )
    let payload = UpdateUserProfileRequest(userProfile: profile)

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(UpdateUserProfileRequest.self, from: encoded)

    #expect(decoded == payload)
}

@Test func deleteUserProfileResponseRoundTripJSON() throws {
    let payload = DeleteUserProfileResponse(success: true, message: "Profile deleted")

    let encoded = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(DeleteUserProfileResponse.self, from: encoded)

    #expect(decoded == payload)
}
