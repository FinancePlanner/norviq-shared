# Norviq Guided Start + Resumable Funnel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** New or unfinished Norviq users resume the first-run funnel wherever they sign in, then get a server-tracked "Get started with Norviq" card that walks them through adding a holding, setting a budget, and setting a goal, on web and iOS.

**Architecture:** The backend owns one `onboarding_state` row per user. Clients write the funnel position and the card's dismissal to it. The three guided "latches" are written only by the backend, as a side effect of the real write. Web (Go/templ/HTMX) renders the card server-side and keeps the active step in the session. iOS (SwiftUI) ports Lumina's `GuidedStartCoordinator`, its anchors and its spotlight. The shared DTOs ship in norviq-shared v5.13.0.

**Tech Stack:**

| Repo | Stack |
|---|---|
| norviq-shared | Swift 6 package, Swift Testing |
| norviq-backend | Vapor 4, Fluent, Postgres, SQLKit raw SQL, Swift Testing + VaporTesting |
| norviq-web | Go, chi, templ, HTMX 4, Alpine 3, scs sessions, testify, Parcel via bun |
| norviq-ios | SwiftUI (iOS 17+), Factory, AnyAPI `BaseHTTPClient`, PostHog, XCTest/Swift Testing |

**Spec:** `norviq-shared/docs/guided-start.md`. Read it before any task. When this plan and the spec disagree, the spec wins; stop and flag the disagreement.

## Global Constraints

- **Step ids:** `add_holding`, `set_budget`, `set_goal`.
- **Targets:** `holding-add`, `budget-salary`, `goal-create`, plus the iOS-only hop `goal-card`.
- **Funnel step ids:** `questionnaire`, `paywall`, `welcome`, `import`, `budget`, `done`.
- **Copy:**
  - Card headline: `Get started with Norviq`.
  - Progress label: `n of 3`.
  - Completion line: `You're set up. Everything else builds on these three.`
  - Skip label: `Skip`.
  - Step lines:
    - `add_holding`: "Add one stock or ETF you own."
    - `set_budget`: "Enter your monthly take-home pay."
    - `set_goal`: "Pick one thing you're saving for."
- **Poll schedule:** 1s, 2s, 4s, 8s, then every 10s. Give up 5 minutes after the step opened.
- **Latches:** never set by a client. `PATCH /v1/onboarding` accepts only `funnelStep`, `funnelCompleted: true` and `guidedStartDismissed`. Any other key gets a 400.
- **Visibility:** `visible := loaded && funnelCompletedAt != nil && !allDone && !dismissed`, with two exceptions:
  - a step in progress keeps the card visible;
  - "Show me around" on a finished wizard shows the completed card for that session only.
- **PostHog event names** are unprefixed and identical on web and iOS:
  - `guided_start_card_shown`
  - `guided_start_step_started`
  - `guided_start_step_completed`
  - `guided_start_step_skipped`
  - `guided_start_step_timed_out`
  - `guided_start_dismissed`
  - `guided_start_reopened`
  - `guided_start_completed`
  - `onboarding_funnel_resumed`
- **No mascot and no confetti.** Every animation respects reduced motion.
- **No anchor, no dim:** a step whose target is not on screen shows its line without a scrim.
- **Mid-flight work in these repos:** Muse Stage D touches `norviq-ios` (URL scheme and push routing in `ContentView`). Work only in the worktrees Task 0 creates, off `origin/main`. Never touch `*-muse` directories.
- **Line numbers in this plan** come from a local checkout that may be behind `origin/main`. Always locate anchors by the quoted symbol or string, never by line number alone.

## Review Focus

1. **Backend slow or down while the web gate runs.** The gate must fail closed (stay in the funnel), within 3s, and must not cache completion. Pinned by `TestResumeFailsClosedWhenBackendErrors` (Task 4).
2. **The latch write fails.** The user's real action (adding a stock) must still succeed. Pinned by `latchFailureNeverFailsTheAction` (Task 3).
3. **Automatic budget-snapshot creation** from the month rollover on `GET /v1/budget/snapshots` must not latch `set_budget`. Pinned by `rolloverDoesNotLatchBudget` (Task 3).
4. **Target not on screen.** A user with holdings sees "Add position" only inside a toolbar menu. There must be no dim and no dead scrim over the page. Pinned by `noHoleMeansNoScrim` (iOS, Task 9) and by the JS `found=false` path (web, Task 7, manual check in Task 11).
5. **Duplicate or late client writes.** A second `funnelCompleted: true` must keep the first timestamp, and a dismissal arriving mid-step must not yank the open step. Pinned by `funnelCompletionIsOneWayAndIdempotent` (Task 2) and `dismissalElsewhereWaitsForOpenStep` (Task 9).

---

## File map

**norviq-shared**
- Create: `Sources/StockPlanShared/Onboarding/OnboardingDTOs.swift`, which holds `OnboardingFunnelStep`, `OnboardingStateDTO` and `OnboardingPatchRequest`.
- Create: `Tests/StockPlanSharedTests/OnboardingDTOsTests.swift`.
- Move in: `docs/guided-start.md` (the spec) and this plan.

**norviq-backend** (`Sources/StockPlanBackend/` = `S/`)

| Action | File |
|---|---|
| Create | `S/Onboarding/OnboardingState.swift` (Fluent model and `toDTO()`) |
| Create | `S/Onboarding/OnboardingStateService.swift` (fetch-or-create, apply patch) |
| Create | `S/Onboarding/OnboardingLatches.swift` (`OnboardingLatch`, the upsert, and `Request.latchOnboarding`) |
| Create | `S/Onboarding/OnboardingController.swift` |
| Create | `S/Migrations/CreateOnboardingState.swift` (table and `OnboardingBackfill`) |
| Modify | `S/ConfigureBootstrap.swift` (register the migration) |
| Modify | `S/routes.swift` (register the controller) |
| Modify | `S/Shared/StockPlanShared+Content.swift` (Content conformances) |
| Modify | `S/openapi.yaml` |
| Modify | `Tests/StockPlanBackendTests/OpenAPIDocsTests.swift` |
| Modify (latch calls) | `S/Stocks/StockService.swift`, `S/Broker/BrokerController.swift`, `S/Expenses/BudgetController.swift`, `S/GoalPlanning/GoalPlanningController.swift` |
| Modify | `Package.swift` (pin norviq-shared 5.13.0 at release time) |
| Create | `Tests/StockPlanBackendTests/OnboardingTests.swift` |
| Create | `Tests/StockPlanBackendTests/OnboardingLatchTests.swift` |

**norviq-web**

*Funnel*
- Create: `internal/api/onboarding.go`, the progress types and `GetOnboardingProgress`/`PatchOnboardingProgress`.
- Modify: `internal/onboarding/gate.go`, adding `Resume` and `FunnelPath`, and making `Needs` and `PostAuthRedirect` take `*api.Service`.
- Modify the gate's callers:
  - `internal/middleware/onboarding.go`
  - `internal/middleware/auth.go` (`RedirectIfAuthenticated`)
  - `internal/handlers/onboarding_gate.go`
  - `internal/handlers/onboarding.go` (`guardInProgress`, plus step recording)
- Create: `internal/onboarding/resume_test.go` and `internal/handlers/onboarding_funnel_sync_test.go`.

*Guided start*
- Create:
  - `internal/guide/guide.go` and `guide_test.go` (pure step, visibility and delay logic)
  - `internal/session/guided_start.go` and `guided_start_test.go`
  - `internal/handlers/guided_start.go` and `guided_start_test.go`
  - `internal/pages/guidedstart/guidedstart.templ` and `guidedstart_test.go`
  - `internal/server/assets/guided-start.js`
  - `internal/server/assets/css/guided-start.css`
- Modify:
  - `internal/handlers/app.go` (`renderShell`, `Dashboard`, `DashboardPulse`)
  - `internal/pages/dashboard/viewmodel.go`, `command_center.templ`, `pulse.templ`
  - `internal/server/server.go` (routes)
  - `internal/server/assets/scripts.js`, `internal/server/assets/styles.css`
  - the targets: `internal/pages/portfolio/holdings.templ`, `internal/pages/expenses/planner.templ`, `internal/pages/goals/page.templ`
  - the local-action notes, in the handlers `PortfolioCreatePosition`, `ExpensesSalarySubmit` and `FinancialGoalCreate`
  - `internal/pages/settings/settings.templ` ("Show me around")

**norviq-ios** (app sources `financeplan/financeplan/` = `F/`, tests `financeplan/financeplanTests/` = `T/`)

*Client and funnel*
- Create:
  - `F/API/Onboarding/OnboardingEndpoints.swift`
  - `F/API/Onboarding/OnboardingHTTPClient.swift`
  - `F/API/Onboarding/Container+OnboardingFactories.swift`
  - `F/Features/Onboarding/OnboardingStateStore.swift`
  - `F/Features/Onboarding/OnboardingFunnelRouting.swift`
- Modify: `F/ContentView.swift`.

*Guided start*
- Create, under `F/Features/Home/GuidedStart/`:
  - `GuidedStartStep.swift`
  - `GuidedAnchors.swift`
  - `GuidedStartTelemetry.swift`
  - `GuidedStartCoordinator.swift`
  - `GuidedStartHost.swift`
  - `GuidedStartCard.swift`
  - `GuidedSpotlightOverlay.swift`
- Modify:
  - `F/Features/Home/HomeScreen.swift`
  - `F/Features/Home/DashboardRoot.swift`
  - `F/Features/Portfolio/PortfolioListContent.swift`, `F/Features/Portfolio/PortfolioScreen.swift`
  - `F/Features/Expenses/ExpensesPlannerScreen.swift`
  - `F/Features/GoalPlanning/GoalPlanningScreen.swift`
  - `F/Features/UserProfile/UserProfileView.swift`
  - `financeplan.xcodeproj/project.pbxproj` (shared pin)

*Tests*
- Create: `T/OnboardingHTTPClientTests.swift`, `T/OnboardingFunnelRoutingTests.swift`, `T/GuidedStartCoordinatorTests.swift`, `T/GuidedSpotlightGeometryTests.swift`.

---

### Task 0: Worktrees

**Files:** none (git only).

- [ ] **Step 1: Create one worktree per repo off `origin/main`, on branch `feat/guided-start`**

```bash
cd ~/Work/production/apps/norviq
for repo in norviq-shared norviq-backend norviq-web; do
  git -C "$repo" fetch origin
  git -C "$repo" worktree add "../${repo}-guided" -b feat/guided-start origin/main
done
git -C norviq-ios/financeplan fetch origin
git -C norviq-ios/financeplan worktree add ../../norviq-ios-guided -b feat/guided-start origin/main
```

Expected: `norviq-shared-guided/`, `norviq-backend-guided/`, `norviq-web-guided/` and `norviq-ios-guided/` exist next to the originals. The iOS worktree root is the git root, and its sources are under `financeplan/`.

- [ ] **Step 2: Move the spec and this plan into the shared worktree**

```bash
cd ~/Work/production/apps/norviq
mkdir -p norviq-shared-guided/docs/plans
mv norviq-shared/docs/guided-start.md norviq-shared-guided/docs/guided-start.md
mv norviq-shared/docs/plans/2026-09-24-guided-start.md norviq-shared-guided/docs/plans/
git -C norviq-shared-guided add docs
git -C norviq-shared-guided commit -m "docs: guided start contract and implementation plan"
```

- [ ] **Step 3: Check that the pins on `origin/main` are what the plan expects**

```bash
grep -n 'norviq-shared.git' norviq-backend-guided/Package.swift
grep -n -A3 'norviq-shared.git' norviq-ios-guided/financeplan.xcodeproj/project.pbxproj
git -C norviq-shared-guided tag --list 'v5.1*' | sort -V | tail -3
```

Expected: both pins say `5.12.0`, and the latest tag is `v5.12.0`. If a newer tag exists, use the next free minor instead of `5.13.0` everywhere below.

---

### Task 1: Shared onboarding DTOs

**Files:**
- Create: `norviq-shared-guided/Sources/StockPlanShared/Onboarding/OnboardingDTOs.swift`
- Test: `norviq-shared-guided/Tests/StockPlanSharedTests/OnboardingDTOsTests.swift`

**Interfaces:**
- Produces:
  - `public enum OnboardingFunnelStep: String, Codable, Sendable, CaseIterable`, with cases `questionnaire`, `paywall`, `welcome`, `import`, `budget`, `done`.
  - `public struct OnboardingStateDTO: Codable, Sendable, Equatable`, with fields `funnelStep: String?`, `funnelCompletedAt: Date?`, `addHoldingCompleted: Bool`, `firstHoldingAt: Date?`, `setBudgetCompleted: Bool`, `firstBudgetAt: Date?`, `setGoalCompleted: Bool`, `firstGoalAt: Date?` and `guidedStartDismissedAt: Date?`. Its memberwise init has defaults.
  - `public struct OnboardingPatchRequest: Codable, Sendable, Equatable`, with fields `funnelStep: String?`, `funnelCompleted: Bool?` and `guidedStartDismissed: Bool?`.

- [ ] **Step 1: Write the failing test**

```swift
import Foundation
@testable import StockPlanShared
import Testing

struct OnboardingDTOsTests {
    @Test
    func `state decodes the camelCase ISO-8601 wire shape the backend sends`() throws {
        let json = """
        {"funnelStep":"budget","funnelCompletedAt":null,
         "addHoldingCompleted":true,"firstHoldingAt":"2026-09-24T10:00:00Z",
         "setBudgetCompleted":false,"firstBudgetAt":null,
         "setGoalCompleted":false,"firstGoalAt":null,
         "guidedStartDismissedAt":null}
        """
        let state = try JSONDecoder.makeStockPlanShared().decode(OnboardingStateDTO.self, from: Data(json.utf8))
        #expect(state.funnelStep == OnboardingFunnelStep.budget.rawValue)
        #expect(state.addHoldingCompleted)
        #expect(state.firstHoldingAt == ISO8601DateFormatter().date(from: "2026-09-24T10:00:00Z"))
        #expect(state.funnelCompletedAt == nil)
    }

    @Test
    func `patch encodes only the fields that are set`() throws {
        let data = try JSONEncoder().encode(OnboardingPatchRequest(guidedStartDismissed: true))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["guidedStartDismissed"])
    }

    @Test(arguments: OnboardingFunnelStep.allCases)
    func `funnel step ids match the contract`(_ step: OnboardingFunnelStep) {
        #expect(["questionnaire", "paywall", "welcome", "import", "budget", "done"].contains(step.rawValue))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd norviq-shared-guided && swift test --filter OnboardingDTOsTests`
Expected: the build fails with "cannot find 'OnboardingStateDTO' in scope".

- [ ] **Step 3: Write the DTOs**

```swift
import Foundation

// Server-owned onboarding progress. The contract is docs/guided-start.md.

/// Where a user is in the first-run funnel. Carried on the wire as a string so
/// an older client never fails to decode a step a newer one wrote.
public enum OnboardingFunnelStep: String, Codable, Sendable, CaseIterable {
    case questionnaire
    case paywall
    case welcome
    case `import`
    case budget
    case done
}

public struct OnboardingStateDTO: Codable, Sendable, Equatable {
    public let funnelStep: String?
    public let funnelCompletedAt: Date?
    public let addHoldingCompleted: Bool
    public let firstHoldingAt: Date?
    public let setBudgetCompleted: Bool
    public let firstBudgetAt: Date?
    public let setGoalCompleted: Bool
    public let firstGoalAt: Date?
    public let guidedStartDismissedAt: Date?

    public init(
        funnelStep: String? = nil,
        funnelCompletedAt: Date? = nil,
        addHoldingCompleted: Bool = false,
        firstHoldingAt: Date? = nil,
        setBudgetCompleted: Bool = false,
        firstBudgetAt: Date? = nil,
        setGoalCompleted: Bool = false,
        firstGoalAt: Date? = nil,
        guidedStartDismissedAt: Date? = nil
    ) {
        self.funnelStep = funnelStep
        self.funnelCompletedAt = funnelCompletedAt
        self.addHoldingCompleted = addHoldingCompleted
        self.firstHoldingAt = firstHoldingAt
        self.setBudgetCompleted = setBudgetCompleted
        self.firstBudgetAt = firstBudgetAt
        self.setGoalCompleted = setGoalCompleted
        self.firstGoalAt = firstGoalAt
        self.guidedStartDismissedAt = guidedStartDismissedAt
    }
}

/// The only fields a client may write. Guided-start latches are absent on
/// purpose: the server sets them as a side effect of the real action.
public struct OnboardingPatchRequest: Codable, Sendable, Equatable {
    public let funnelStep: String?
    /// One-way. The server rejects `false`.
    public let funnelCompleted: Bool?
    public let guidedStartDismissed: Bool?

    public init(funnelStep: String? = nil, funnelCompleted: Bool? = nil, guidedStartDismissed: Bool? = nil) {
        self.funnelStep = funnelStep
        self.funnelCompleted = funnelCompleted
        self.guidedStartDismissed = guidedStartDismissed
    }
}
```

`JSONEncoder` omits nil optionals by default (it uses `encodeIfPresent`), which is what the second test relies on.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd norviq-shared-guided && swift test --filter OnboardingDTOsTests`
Expected: PASS, 3 tests (plus the 6 parameterized cases).

- [ ] **Step 5: Commit**

```bash
git -C norviq-shared-guided add Sources/StockPlanShared/Onboarding Tests/StockPlanSharedTests/OnboardingDTOsTests.swift
git -C norviq-shared-guided commit -m "feat(onboarding): shared onboarding state and patch DTOs"
```

Do not tag here. Tagging `v5.13.0` happens at merge time (Task 11). Until then, the backend builds against the worktree with `STOCKPLAN_SHARED_PATH`.

---

### Task 2: Backend table, backfill and `GET`/`PATCH /v1/onboarding`

**Files:**
- Create: `S/Onboarding/OnboardingState.swift`, `S/Onboarding/OnboardingStateService.swift`, `S/Onboarding/OnboardingController.swift`, `S/Migrations/CreateOnboardingState.swift`
- Modify: `S/ConfigureBootstrap.swift`, `S/routes.swift`, `S/Shared/StockPlanShared+Content.swift`, `S/openapi.yaml`, `Tests/StockPlanBackendTests/OpenAPIDocsTests.swift`
- Test: `Tests/StockPlanBackendTests/OnboardingTests.swift`

**Interfaces:**
- Consumes: Task 1's DTOs.
- Produces:
  - `final class OnboardingState: Model`, with table `onboarding_state` and `func toDTO() -> OnboardingStateDTO`.
  - `enum OnboardingStateService`, with `static func fetchOrCreate(userId: UUID, on db: any Database) async throws -> OnboardingState` and `static func apply(_ patch: OnboardingPatchRequest, userId: UUID, on db: any Database, now: Date = Date()) async throws -> OnboardingState`.
  - `enum OnboardingBackfill`, with `static func run(on sql: any SQLDatabase) async throws`.
  - `struct OnboardingController: RouteCollection`.

All backend commands run in `norviq-backend-guided` with the environment variable `STOCKPLAN_SHARED_PATH=$HOME/Work/production/apps/norviq/norviq-shared-guided` and a local Postgres from `docker compose -f docker-compose.dev.yml up -d` (credentials in `.env`).

- [ ] **Step 1: Write the failing tests**

```swift
import FluentSQL
import Foundation
@testable import StockPlanBackend
import StockPlanShared
import Testing
import VaporTesting

@Suite("Onboarding state", .serialized)
struct OnboardingTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        try await DatabaseTestLock.withSharedAccess {
            let app = try await Application.make(.testing)
            do {
                try await configure(app)
                try await app.autoMigrate()
                try await test(app)
                try await app.autoRevert()
            } catch {
                try? await app.autoRevert()
                try await app.asyncShutdown()
                throw error
            }
            try await app.asyncShutdown()
        }
    }

    private func registerUser(on app: Application, identifier: String) async throws -> AuthResponse {
        let request = AuthRegisterRequest(
            username: "onboarding_\(identifier)",
            password: "Password123!",
            confirmPassword: "Password123!",
            email: "onboarding+\(identifier)@example.com",
            dateOfBirth: Date(timeIntervalSince1970: 946_684_800)
        )
        var response: AuthResponse?
        try await app.testing().test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(request)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            response = try res.content.decode(AuthResponse.self)
        })
        return try #require(response)
    }

    private func getState(_ app: Application, token: String) async throws -> OnboardingStateDTO {
        var state: OnboardingStateDTO?
        try await app.testing().test(.GET, "v1/onboarding", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            state = try res.content.decode(OnboardingStateDTO.self)
        })
        return try #require(state)
    }

    /// Sends a raw JSON body so tests can send keys the DTO does not have.
    private func patch(_ app: Application, token: String, json: String) async throws -> (HTTPStatus, OnboardingStateDTO?) {
        var status: HTTPStatus = .internalServerError
        var state: OnboardingStateDTO?
        try await app.testing().test(.PATCH, "v1/onboarding", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            req.headers.contentType = .json
            req.body = ByteBuffer(string: json)
        }, afterResponse: { res async throws in
            status = res.status
            if res.status == .ok { state = try res.content.decode(OnboardingStateDTO.self) }
        })
        return (status, state)
    }

    @Test("A new account starts with nothing done and no funnel position")
    func freshAccount() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "fresh")
            let state = try await getState(app, token: auth.token)
            #expect(state == OnboardingStateDTO())
        }
    }

    @Test("Unauthenticated reads are rejected")
    func unauthenticated() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "v1/onboarding", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("Funnel step is stored and returned")
    func funnelStep() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "step")
            let (status, state) = try await patch(app, token: auth.token, json: #"{"funnelStep":"budget"}"#)
            #expect(status == .ok)
            #expect(state?.funnelStep == "budget")
            #expect(try await getState(app, token: auth.token).funnelStep == "budget")
        }
    }

    @Test("Unknown funnel steps are rejected")
    func unknownStep() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "badstep")
            let (status, _) = try await patch(app, token: auth.token, json: #"{"funnelStep":"nirvana"}"#)
            #expect(status == .badRequest)
        }
    }

    @Test("Funnel completion is one-way and keeps its first timestamp")
    func funnelCompletionIsOneWayAndIdempotent() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "done")
            let (_, first) = try await patch(app, token: auth.token, json: #"{"funnelCompleted":true}"#)
            let firstAt = try #require(first?.funnelCompletedAt)
            let (_, second) = try await patch(app, token: auth.token, json: #"{"funnelCompleted":true}"#)
            #expect(second?.funnelCompletedAt == firstAt)
            let (status, _) = try await patch(app, token: auth.token, json: #"{"funnelCompleted":false}"#)
            #expect(status == .badRequest)
        }
    }

    @Test("Clients cannot write guided latches", arguments: [
        #"{"addHoldingCompleted":true}"#,
        #"{"firstHoldingAt":"2026-09-24T10:00:00Z"}"#,
        #"{"set_budget_completed":true}"#,
        #"{"funnelStep":"budget","setGoalCompleted":true}"#,
    ])
    func latchesAreServerOwned(_ json: String) async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "latch\(abs(json.hashValue) % 10_000)")
            let (status, _) = try await patch(app, token: auth.token, json: json)
            #expect(status == .badRequest)
            #expect(try await getState(app, token: auth.token) == OnboardingStateDTO())
        }
    }

    @Test("Dismissal is two-way")
    func dismissal() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "dismiss")
            let (_, hidden) = try await patch(app, token: auth.token, json: #"{"guidedStartDismissed":true}"#)
            #expect(hidden?.guidedStartDismissedAt != nil)
            let (_, shown) = try await patch(app, token: auth.token, json: #"{"guidedStartDismissed":false}"#)
            #expect(shown?.guidedStartDismissedAt == nil)
        }
    }

    @Test("Backfill finishes the funnel and hides the card for existing accounts only")
    func backfill() async throws {
        try await withApp { app in
            let existing = try await registerUser(on: app, identifier: "legacy")
            let alreadyRead = try await registerUser(on: app, identifier: "hasrow")
            _ = try await getState(app, token: alreadyRead.token)  // creates its row first

            let sql = try #require(app.db as? any SQLDatabase)
            try await OnboardingBackfill.run(on: sql)

            let legacy = try await getState(app, token: existing.token)
            #expect(legacy.funnelCompletedAt != nil)
            #expect(legacy.guidedStartDismissedAt != nil)

            let untouched = try await getState(app, token: alreadyRead.token)
            #expect(untouched.funnelCompletedAt == nil)
            #expect(untouched.guidedStartDismissedAt == nil)
        }
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `LOG_LEVEL=warning swift test --filter OnboardingTests`
Expected: the build fails with "cannot find 'OnboardingBackfill' in scope".

- [ ] **Step 3: Write the migration and backfill** in `S/Migrations/CreateOnboardingState.swift`

```swift
import Fluent
import FluentSQL

/// One row per user: funnel position, the three guided-start latches, and the
/// card's dismissal. Contract: norviq-shared/docs/guided-start.md.
struct CreateOnboardingState: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
        CREATE TABLE IF NOT EXISTS onboarding_state (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
            funnel_step TEXT,
            funnel_completed_at TIMESTAMPTZ,
            first_holding_at TIMESTAMPTZ,
            first_budget_at TIMESTAMPTZ,
            first_goal_at TIMESTAMPTZ,
            guided_start_dismissed_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ
        )
        """).run()
        try await OnboardingBackfill.run(on: sql)
    }

    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("DROP TABLE IF EXISTS onboarding_state").run()
    }
}

/// Every account that exists when this runs has finished its funnel and does
/// not get the card pushed at it; "Show me around" brings it back with real
/// progress. Rows that already exist are left alone.
enum OnboardingBackfill {
    static func run(on sql: any SQLDatabase) async throws {
        try await sql.raw("""
        INSERT INTO onboarding_state (id, user_id, first_holding_at, first_budget_at, first_goal_at,
                                      funnel_completed_at, guided_start_dismissed_at, created_at, updated_at)
        SELECT gen_random_uuid(), u.id,
               (SELECT min(s.created_at) FROM stocks s WHERE s.user_id = u.id),
               (SELECT min(b.created_at) FROM budget_snapshots b WHERE b.user_id = u.id AND b.net_salary > 0),
               (SELECT min(g.created_at) FROM financial_goals g WHERE g.user_id = u.id),
               NOW(), NOW(), NOW(), NOW()
        FROM users u
        ON CONFLICT (user_id) DO NOTHING
        """).run()
    }
}
```

- [ ] **Step 4: Write the model** in `S/Onboarding/OnboardingState.swift`

```swift
import Fluent
import Foundation
import StockPlanShared
import Vapor

final class OnboardingState: Model, @unchecked Sendable {
    static let schema = "onboarding_state"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var userId: UUID

    @OptionalField(key: "funnel_step")
    var funnelStep: String?

    @OptionalField(key: "funnel_completed_at")
    var funnelCompletedAt: Date?

    @OptionalField(key: "first_holding_at")
    var firstHoldingAt: Date?

    @OptionalField(key: "first_budget_at")
    var firstBudgetAt: Date?

    @OptionalField(key: "first_goal_at")
    var firstGoalAt: Date?

    @OptionalField(key: "guided_start_dismissed_at")
    var guidedStartDismissedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    func toDTO() -> OnboardingStateDTO {
        OnboardingStateDTO(
            funnelStep: funnelStep,
            funnelCompletedAt: funnelCompletedAt,
            addHoldingCompleted: firstHoldingAt != nil,
            firstHoldingAt: firstHoldingAt,
            setBudgetCompleted: firstBudgetAt != nil,
            firstBudgetAt: firstBudgetAt,
            setGoalCompleted: firstGoalAt != nil,
            firstGoalAt: firstGoalAt,
            guidedStartDismissedAt: guidedStartDismissedAt
        )
    }
}
```

- [ ] **Step 5: Write the service** in `S/Onboarding/OnboardingStateService.swift`

```swift
import Fluent
import FluentSQL
import Foundation
import StockPlanShared
import Vapor

enum OnboardingStateService {
    /// Reads the user's row, creating an empty one first if needed. The insert
    /// is `ON CONFLICT DO NOTHING` so two first reads racing both succeed.
    static func fetchOrCreate(userId: UUID, on db: any Database) async throws -> OnboardingState {
        if let sql = db as? any SQLDatabase {
            try await sql.raw("""
            INSERT INTO onboarding_state (id, user_id, created_at, updated_at)
            VALUES (\(bind: UUID()), \(bind: userId), NOW(), NOW())
            ON CONFLICT (user_id) DO NOTHING
            """).run()
        }
        guard let row = try await OnboardingState.query(on: db).filter(\.$userId == userId).first() else {
            throw Abort(.internalServerError, reason: "Onboarding state is missing")
        }
        return row
    }

    static func apply(
        _ patch: OnboardingPatchRequest,
        userId: UUID,
        on db: any Database,
        now: Date = Date()
    ) async throws -> OnboardingState {
        let row = try await fetchOrCreate(userId: userId, on: db)
        if let step = patch.funnelStep {
            row.funnelStep = step
        }
        if patch.funnelCompleted == true, row.funnelCompletedAt == nil {
            row.funnelCompletedAt = now
        }
        if let dismissed = patch.guidedStartDismissed {
            row.guidedStartDismissedAt = dismissed ? (row.guidedStartDismissedAt ?? now) : nil
        }
        try await row.save(on: db)
        return row
    }
}
```

- [ ] **Step 6: Write the controller** in `S/Onboarding/OnboardingController.swift`

```swift
import Foundation
import StockPlanShared
import Vapor

struct OnboardingController: RouteCollection {
    /// Everything else on the row is server-owned. Both spellings are accepted
    /// because the backend decoder accepts both.
    static let clientWritableKeys: Set<String> = [
        "funnelStep", "funnel_step",
        "funnelCompleted", "funnel_completed",
        "guidedStartDismissed", "guided_start_dismissed",
    ]

    func boot(routes: any RoutesBuilder) throws {
        let protected = routes.grouped(ScopedBearerAuthenticator(), SessionToken.guardMiddleware())
        let onboarding = protected.grouped("onboarding")
        onboarding.grouped(ScopeRequirementMiddleware(.settingsRead)).get(use: get)
        onboarding.grouped(ScopeRequirementMiddleware(.settingsWrite)).patch(use: patch)
    }

    @Sendable
    func get(req: Request) async throws -> OnboardingStateDTO {
        let session = try req.auth.require(SessionToken.self)
        return try await OnboardingStateService.fetchOrCreate(userId: session.userId, on: req.db).toDTO()
    }

    @Sendable
    func patch(req: Request) async throws -> OnboardingStateDTO {
        let session = try req.auth.require(SessionToken.self)
        let patch = try Self.decodePatch(req)
        return try await OnboardingStateService.apply(patch, userId: session.userId, on: req.db).toDTO()
    }

    static func decodePatch(_ req: Request) throws -> OnboardingPatchRequest {
        guard
            let body = req.body.string,
            let object = try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any]
        else {
            throw Abort(.badRequest, reason: "Expected a JSON object")
        }
        if let rejected = object.keys.sorted().first(where: { !clientWritableKeys.contains($0) }) {
            throw Abort(.badRequest, reason: "\(rejected) is set by the server, not by clients")
        }
        let patch = try req.content.decode(OnboardingPatchRequest.self)
        if patch.funnelCompleted == false {
            throw Abort(.badRequest, reason: "funnelCompleted is one-way")
        }
        if let step = patch.funnelStep, OnboardingFunnelStep(rawValue: step) == nil {
            throw Abort(.badRequest, reason: "Unknown funnel step \(step)")
        }
        return patch
    }
}
```

- [ ] **Step 7: Wire it up**

Make four edits:

1. In `S/ConfigureBootstrap.swift`, append this as the **last** line inside `func registerMigrations(_ app: Application)`:
   ```swift
       app.migrations.add(CreateOnboardingState())
   ```
2. In `S/routes.swift`, add this directly after `try api.register(collection: UserProfileController())`:
   ```swift
       try api.register(collection: OnboardingController())
   ```
3. In `S/Shared/StockPlanShared+Content.swift`, add this under `// MARK: - User Profile`:
   ```swift
   // MARK: - Onboarding

   extension OnboardingStateDTO: @retroactive Content {}
   extension OnboardingPatchRequest: @retroactive Content {}
   ```
4. In `S/openapi.yaml`, add a path block directly after the `/v1/users:` block (the file mixes styles; use the expanded style shown here):
   ```yaml
     /v1/onboarding:
       get:
         operationId: getOnboardingState
         tags: [Onboarding]
         summary: Funnel position, guided-start progress and dismissal for the current user
         security:
           - bearerAuth: []
         responses:
           '200':
             description: OK
             content:
               application/json:
                 schema:
                   $ref: '#/components/schemas/OnboardingStateDTO'
           '401':
             description: Unauthorized
       patch:
         operationId: updateOnboardingState
         tags: [Onboarding]
         summary: Record funnel position, finish the funnel, or dismiss the guided-start card
         description: >-
           Only funnelStep, funnelCompleted (true only) and guidedStartDismissed are accepted.
           Guided-start progress is set by the server when the user performs the real action.
         security:
           - bearerAuth: []
         requestBody:
           required: true
           content:
             application/json:
               schema:
                 $ref: '#/components/schemas/OnboardingPatchRequest'
         responses:
           '200':
             description: OK
             content:
               application/json:
                 schema:
                   $ref: '#/components/schemas/OnboardingStateDTO'
           '400':
             description: A server-owned field was sent, funnelCompleted was false, or the step is unknown
           '401':
             description: Unauthorized
   ```
   Then add these under `components: schemas:`, at 4-space indent, next to `HouseholdPartnerProfileResponse`:
   ```yaml
       OnboardingStateDTO:
         type: object
         required: [addHoldingCompleted, setBudgetCompleted, setGoalCompleted]
         properties:
           funnelStep: { type: string, nullable: true, enum: [questionnaire, paywall, welcome, import, budget, done] }
           funnelCompletedAt: { type: string, format: date-time, nullable: true }
           addHoldingCompleted: { type: boolean }
           firstHoldingAt: { type: string, format: date-time, nullable: true }
           setBudgetCompleted: { type: boolean }
           firstBudgetAt: { type: string, format: date-time, nullable: true }
           setGoalCompleted: { type: boolean }
           firstGoalAt: { type: string, format: date-time, nullable: true }
           guidedStartDismissedAt: { type: string, format: date-time, nullable: true }
       OnboardingPatchRequest:
         type: object
         additionalProperties: false
         properties:
           funnelStep: { type: string, enum: [questionnaire, paywall, welcome, import, budget, done] }
           funnelCompleted: { type: boolean, enum: [true] }
           guidedStartDismissed: { type: boolean }
   ```

Finally, in `Tests/StockPlanBackendTests/OpenAPIDocsTests.swift`, find the test that asserts `body.contains("operationId: getUserProfile")` and add these lines next to it:

```swift
        #expect(body.contains("/v1/onboarding:"))
        #expect(body.contains("operationId: getOnboardingState"))
        #expect(body.contains("operationId: updateOnboardingState"))
```

- [ ] **Step 8: Run the tests to verify they pass**

Run: `LOG_LEVEL=warning swift test --filter "OnboardingTests|OpenAPIDocsTests"`
Expected: PASS. If the OpenAPI generator plugin fails the build, the YAML is malformed; fix the indentation.

- [ ] **Step 9: Commit**

```bash
git add Sources/StockPlanBackend/Onboarding Sources/StockPlanBackend/Migrations/CreateOnboardingState.swift \
  Sources/StockPlanBackend/ConfigureBootstrap.swift Sources/StockPlanBackend/routes.swift \
  Sources/StockPlanBackend/Shared/StockPlanShared+Content.swift Sources/StockPlanBackend/openapi.yaml \
  Tests/StockPlanBackendTests/OnboardingTests.swift Tests/StockPlanBackendTests/OpenAPIDocsTests.swift
git commit -m "feat(onboarding): onboarding_state table, backfill, GET/PATCH /v1/onboarding"
```

---

### Task 3: Backend guided latches at the real write paths

**Files:**
- Create: `S/Onboarding/OnboardingLatches.swift`
- Modify: `S/Stocks/StockService.swift`, `S/Broker/BrokerController.swift`, `S/Expenses/BudgetController.swift`, `S/GoalPlanning/GoalPlanningController.swift`
- Test: `Tests/StockPlanBackendTests/OnboardingLatchTests.swift`

**Interfaces:**
- Consumes: the `onboarding_state` table from Task 2.
- Produces:
  - `enum OnboardingLatch: String`, with cases `holding`, `budget` and `goal`.
  - `enum OnboardingLatches`, with `static func latch(_:userId:on:) async throws`.
  - `extension Request`, with `func latchOnboarding(_ latch: OnboardingLatch, userId: UUID, on db: any Database) async`, which never throws.

- [ ] **Step 1: Write the failing tests**

```swift
import FluentSQL
import Foundation
@testable import StockPlanBackend
import StockPlanShared
import Testing
import VaporTesting

@Suite("Onboarding latches", .serialized)
struct OnboardingLatchTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        try await DatabaseTestLock.withSharedAccess {
            let app = try await Application.make(.testing)
            do {
                try await configure(app)
                try await app.autoMigrate()
                try await test(app)
                try await app.autoRevert()
            } catch {
                try? await app.autoRevert()
                try await app.asyncShutdown()
                throw error
            }
            try await app.asyncShutdown()
        }
    }

    private func registerUser(on app: Application, identifier: String) async throws -> AuthResponse {
        let request = AuthRegisterRequest(
            username: "latch_\(identifier)",
            password: "Password123!",
            confirmPassword: "Password123!",
            email: "latch+\(identifier)@example.com",
            dateOfBirth: Date(timeIntervalSince1970: 946_684_800)
        )
        var response: AuthResponse?
        try await app.testing().test(.POST, "v1/auth/register", beforeRequest: { req in
            try req.content.encode(request)
        }, afterResponse: { res async throws in
            response = try res.content.decode(AuthResponse.self)
        })
        return try #require(response)
    }

    private func state(_ app: Application, _ token: String) async throws -> OnboardingStateDTO {
        var state: OnboardingStateDTO?
        try await app.testing().test(.GET, "v1/onboarding", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
        }, afterResponse: { res async throws in
            state = try res.content.decode(OnboardingStateDTO.self)
        })
        return try #require(state)
    }

    private func addStock(_ app: Application, _ token: String, symbol: String = "AAPL") async throws -> HTTPStatus {
        var status: HTTPStatus = .internalServerError
        try await app.testing().test(.POST, "v1/stocks", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(StockRequest(symbol: symbol, shares: 1, buyPrice: 100, buyDate: "2026-01-01", notes: nil))
        }, afterResponse: { res async in
            status = res.status
        })
        return status
    }

    private func createSnapshot(_ app: Application, _ token: String, netSalary: Double) async throws {
        try await app.testing().test(.POST, "v1/budget/snapshots", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(BudgetSnapshotRequest(monthStart: "2026-09-01", netSalary: netSalary, targetShares: [:]))
        }, afterResponse: { res async in
            #expect(res.status == .created)
        })
    }

    @Test("Adding a stock latches add_holding, once")
    func holdingLatch() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "holding")
            #expect(try await addStock(app, auth.token) == .ok)
            let first = try await state(app, auth.token)
            #expect(first.addHoldingCompleted)
            #expect(first.funnelStep == nil)  // latching created the row without touching the funnel

            _ = try await addStock(app, auth.token, symbol: "MSFT")
            #expect(try await state(app, auth.token).firstHoldingAt == first.firstHoldingAt)
        }
    }

    @Test("A budget with a salary latches set_budget; a zero-salary budget does not")
    func budgetLatch() async throws {
        try await withApp { app in
            let zero = try await registerUser(on: app, identifier: "zerosalary")
            try await createSnapshot(app, zero.token, netSalary: 0)
            #expect(try await state(app, zero.token).setBudgetCompleted == false)

            let paid = try await registerUser(on: app, identifier: "salary")
            try await createSnapshot(app, paid.token, netSalary: 3000)
            #expect(try await state(app, paid.token).setBudgetCompleted)
        }
    }

    @Test("Opening the planner auto-creates a month but does not latch set_budget")
    func rolloverDoesNotLatchBudget() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "rollover")
            try await app.testing().test(.GET, "v1/budget/snapshots", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: auth.token)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
            #expect(try await state(app, auth.token).setBudgetCompleted == false)
        }
    }

    @Test("Creating a financial goal latches set_goal")
    func goalLatch() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "goal")
            let portfolio = PortfolioList(userId: auth.userId, name: "Goal", isDefault: false)
            try await portfolio.save(on: app.db)
            let input = FinancialGoalInput(
                name: "House",
                targetAmount: 50000,
                targetDate: "2036-01-01",
                baseCurrency: "EUR",
                startingCapital: 10000,
                monthlyContribution: 200,
                annualContributionGrowth: 0,
                inflationAssumption: 0,
                expectedAnnualReturn: 0.06,
                portfolioAllocations: [
                    GoalPortfolioAllocation(id: UUID().uuidString, portfolioListId: try portfolio.requireID().uuidString, allocationPercentage: 100),
                ]
            )
            try await app.testing().test(.POST, "v1/financial-goals", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: auth.token)
                try req.content.encode(input)
            }, afterResponse: { res async in
                #expect(res.status == .ok || res.status == .created)
            })
            #expect(try await state(app, auth.token).setGoalCompleted)
        }
    }

    @Test("A failing latch never fails the user's action")
    func latchFailureNeverFailsTheAction() async throws {
        try await withApp { app in
            let auth = try await registerUser(on: app, identifier: "latchfail")
            let sql = try #require(app.db as? any SQLDatabase)
            try await sql.raw("DROP TABLE onboarding_state").run()
            #expect(try await addStock(app, auth.token) == .ok)
        }
    }
}
```

`FinancialGoalInput`, `GoalPortfolioAllocation` and `PortfolioList` are used exactly as `GoalProjectionFieldsTests.makeGoal`/`seedPortfolio` use them. If the initializer labels differ on `origin/main`, copy them from that file.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `LOG_LEVEL=warning swift test --filter OnboardingLatchTests`
Expected: `holdingLatch`, `budgetLatch` and `goalLatch` fail with `addHoldingCompleted`/`setBudgetCompleted`/`setGoalCompleted` false. `rolloverDoesNotLatchBudget` and `latchFailureNeverFailsTheAction` pass, because nothing latches yet.

- [ ] **Step 3: Write the latch helper** in `S/Onboarding/OnboardingLatches.swift`

```swift
import Fluent
import FluentSQL
import Foundation
import Vapor

/// A guided-start latch and the column it stamps.
enum OnboardingLatch: String, CaseIterable, Sendable {
    case holding = "first_holding_at"
    case budget = "first_budget_at"
    case goal = "first_goal_at"
}

enum OnboardingLatches {
    /// Stamps the latch once. The row may not exist yet — a user can add a
    /// holding before any client has read onboarding state — so this upserts.
    static func latch(_ latch: OnboardingLatch, userId: UUID, on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else { return }
        let column = latch.rawValue
        try await sql.raw("""
        INSERT INTO onboarding_state (id, user_id, \(unsafeRaw: column), created_at, updated_at)
        VALUES (\(bind: UUID()), \(bind: userId), NOW(), NOW(), NOW())
        ON CONFLICT (user_id) DO UPDATE
        SET \(unsafeRaw: column) = COALESCE(onboarding_state.\(unsafeRaw: column), EXCLUDED.\(unsafeRaw: column)),
            updated_at = NOW()
        """).run()
    }
}

extension Request {
    /// Best-effort: the user's action already succeeded, and a missed latch
    /// only costs a guided-start tick.
    func latchOnboarding(_ latch: OnboardingLatch, userId: UUID, on db: any Database) async {
        do {
            try await OnboardingLatches.latch(latch, userId: userId, on: db)
        } catch {
            logger.warning("onboarding latch failed latch=\(latch.rawValue) user=\(userId) error=\(error)")
        }
    }
}
```

- [ ] **Step 4: Call it at the four write paths**

1. **`S/Stocks/StockService.swift`, in `StockServiceImpl.create`.** Directly after `await req.reconcileBadges(userId: userId, on: db)` and before `return try StockResponse(from: stock)`:
   ```swift
           await req.latchOnboarding(.holding, userId: userId, on: db)
   ```
   Also in `StockServiceImpl.bulkCreate`, inside `if created > 0 {`, directly after `await req.reconcileBadges(userId: userId, on: db)`:
   ```swift
               await req.latchOnboarding(.holding, userId: userId, on: db)
   ```
2. **`S/Broker/BrokerController.swift`, in both `importCsvCommit` and `importScreenshotCommit`.** Directly after `await req.reconcileBadges(userId: session.userId, on: req.db)`:
   ```swift
           if !response.inserted.isEmpty || !response.updated.isEmpty {
               await req.latchOnboarding(.holding, userId: session.userId, on: req.db)
           }
   ```
3. **`S/Expenses/BudgetController.swift`.** Replace the bodies of `createSnapshot` and `updateSnapshot` with the following. The only change is the latch call. Leave `getSnapshots` and `ExpensesService` untouched, because the rollover lives there.
   ```swift
       @Sendable
       func createSnapshot(req: Request) async throws -> Response {
           let session = try req.auth.require(SessionToken.self)
           // Monthly budget snapshot creation is free — no Pro gate required.
           let payload = try req.content.decode(BudgetSnapshotPayload.self).asRequest()

           let created = try await req.expensesService.createBudgetSnapshot(
               userId: session.userId,
               request: payload,
               on: req.db
           )
           // Latched here and not in the service: the service also runs for the
           // automatic month rollover, which is not the user setting a budget.
           if created.netSalary > 0 {
               await req.latchOnboarding(.budget, userId: session.userId, on: req.db)
           }
           let res = Response(status: .created)
           try res.content.encode(created)
           return res
       }

       @Sendable
       func updateSnapshot(req: Request) async throws -> BudgetSnapshotResponse {
           let session = try req.auth.require(SessionToken.self)
           // Snapshot update is free — no Pro gate required.
           let snapshotId = try requireUUIDParameter(req, name: "snapshotId")
           let payload = try req.content.decode(BudgetSnapshotPayload.self).asRequest()

           let updated = try await req.expensesService.updateSnapshot(
               userId: session.userId,
               snapshotId: snapshotId,
               request: payload,
               on: req.db
           )
           if updated.netSalary > 0 {
               await req.latchOnboarding(.budget, userId: session.userId, on: req.db)
           }
           return updated
       }
   ```
   If `createBudgetSnapshot` returns a type without `netSalary`, use `payload.netSalary > 0` instead (the payload is `BudgetSnapshotRequest`).
4. **`S/GoalPlanning/GoalPlanningController.swift`, in `create`.** Replace `return try await service.goalDTO(goal, on: req.db)` with:
   ```swift
           await req.latchOnboarding(.goal, userId: userId, on: req.db)
           return try await service.goalDTO(goal, on: req.db)
   ```

Do **not** latch in `ScenarioController.createGoal` (it is unrouted), in `GoalsController.create` (focus-point goals are a different feature), in IBKR sync, or in the portfolio clone.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `LOG_LEVEL=warning swift test --filter "OnboardingLatchTests|OnboardingTests"`
Expected: PASS.

- [ ] **Step 6: Run the full backend suite**

Run: `make backend-test`
Expected: PASS with no new failures. `latchFailureNeverFailsTheAction` drops the table mid-test; the revert uses `IF EXISTS`, so teardown still works.

- [ ] **Step 7: Commit**

```bash
git add Sources/StockPlanBackend/Onboarding/OnboardingLatches.swift Sources/StockPlanBackend/Stocks/StockService.swift \
  Sources/StockPlanBackend/Broker/BrokerController.swift Sources/StockPlanBackend/Expenses/BudgetController.swift \
  Sources/StockPlanBackend/GoalPlanning/GoalPlanningController.swift Tests/StockPlanBackendTests/OnboardingLatchTests.swift
git commit -m "feat(onboarding): latch guided-start steps at the real write paths"
```

---

### Task 4: Web resumes the funnel from the server

**Files:**
- Create: `internal/api/onboarding.go`, `internal/onboarding/resume_test.go`, `internal/handlers/onboarding_funnel_sync_test.go`
- Modify: `internal/onboarding/gate.go`, `internal/middleware/onboarding.go`, `internal/middleware/auth.go`, `internal/handlers/onboarding_gate.go`, `internal/handlers/onboarding.go`

**Interfaces:**
- Consumes: `GET`/`PATCH /v1/onboarding` from Task 2.
- Produces:
  - `api.OnboardingProgress`
  - `api.OnboardingProgressPatch`
  - `(*api.Service).GetOnboardingProgress(ctx, editors...) (*api.OnboardingProgress, error)`
  - `(*api.Service).PatchOnboardingProgress(ctx, api.OnboardingProgressPatch, editors...) (*api.OnboardingProgress, error)`
  - `onboarding.Resume(ctx, sm, r, svc *api.Service, editor) (path string, needs bool)`
  - `onboarding.FunnelPath(step string) string`
  - `onboarding.Needs` and `onboarding.PostAuthRedirect`, now taking `*api.Service`

All web commands run in `norviq-web-guided`. Run `make assets` once first, because the Go build embeds `static/styles.css`.

- [ ] **Step 1: Write the failing tests**

`internal/onboarding/resume_test.go`:

```go
package onboarding

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/alexedwards/scs/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func stubProgress(t *testing.T, status int, body string, hits *atomic.Int32) *api.Service {
	t.Helper()
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits.Add(1)
		require.Equal(t, "/v1/onboarding", r.URL.Path)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_, _ = w.Write([]byte(body))
	}))
	t.Cleanup(backend.Close)
	svc, err := api.NewService(backend.URL)
	require.NoError(t, err)
	return svc
}

// resumeTwice calls Resume twice on one session, so the second call sees
// whatever the first cached.
func resumeTwice(t *testing.T, svc *api.Service) (first, second [2]any) {
	t.Helper()
	sm := scs.New()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/dashboard", http.NoBody)
	sm.LoadAndSave(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		p1, n1 := Resume(r.Context(), sm, r, svc, api.WithBearerToken("token"))
		p2, n2 := Resume(r.Context(), sm, r, svc, api.WithBearerToken("token"))
		first, second = [2]any{p1, n1}, [2]any{p2, n2}
	})).ServeHTTP(httptest.NewRecorder(), req)
	return first, second
}

func TestResumeLandsOnStoredFunnelStep(t *testing.T) {
	t.Parallel()
	var hits atomic.Int32
	svc := stubProgress(t, http.StatusOK, `{"funnelStep":"budget","funnelCompletedAt":null,"addHoldingCompleted":true,"setBudgetCompleted":false,"setGoalCompleted":false}`, &hits)
	first, _ := resumeTwice(t, svc)
	assert.Equal(t, [2]any{"/onboarding/budget", true}, first)
}

func TestResumeCachesCompletionInSession(t *testing.T) {
	t.Parallel()
	var hits atomic.Int32
	svc := stubProgress(t, http.StatusOK, `{"funnelStep":"done","funnelCompletedAt":"2026-09-24T10:00:00Z","addHoldingCompleted":false,"setBudgetCompleted":false,"setGoalCompleted":false}`, &hits)
	first, second := resumeTwice(t, svc)
	assert.Equal(t, [2]any{"", false}, first)
	assert.Equal(t, [2]any{"", false}, second)
	assert.Equal(t, int32(1), hits.Load(), "a finished funnel must not cost a backend call per request")
}

func TestResumeFailsClosedWhenBackendErrors(t *testing.T) {
	t.Parallel()
	var hits atomic.Int32
	svc := stubProgress(t, http.StatusInternalServerError, `{"reason":"boom"}`, &hits)
	first, second := resumeTwice(t, svc)
	assert.Equal(t, [2]any{"/onboarding", true}, first)
	assert.Equal(t, [2]any{"/onboarding", true}, second, "an error must never be cached as completion")
}

func TestFunnelPath(t *testing.T) {
	t.Parallel()
	cases := map[string]string{
		"questionnaire": "/onboarding/questionnaire",
		"paywall":       "/onboarding/paywall",
		"welcome":       "/onboarding",
		"import":        "/onboarding/import",
		"budget":        "/onboarding/budget",
		"":              "/onboarding",
		"unknown":       "/onboarding",
	}
	for step, want := range cases {
		assert.Equal(t, want, FunnelPath(step), step)
	}
}
```

`internal/handlers/onboarding_funnel_sync_test.go`:

```go
package handlers

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/FinancePlanner/StockPlanWeb/internal/config"
	"github.com/FinancePlanner/StockPlanWeb/internal/session"
	"github.com/alexedwards/scs/v2"
	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type funnelBackend struct {
	mu      sync.Mutex
	patches []map[string]any
}

func newFunnelBackend(t *testing.T) (*funnelBackend, *api.Service) {
	t.Helper()
	fb := &funnelBackend{}
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "/v1/onboarding", r.URL.Path)
		if r.Method == http.MethodPatch {
			raw, _ := io.ReadAll(r.Body)
			var body map[string]any
			require.NoError(t, json.Unmarshal(raw, &body))
			fb.mu.Lock()
			fb.patches = append(fb.patches, body)
			fb.mu.Unlock()
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"funnelStep":"import","funnelCompletedAt":null,"addHoldingCompleted":false,"setBudgetCompleted":false,"setGoalCompleted":false}`))
	}))
	t.Cleanup(backend.Close)
	svc, err := api.NewService(backend.URL)
	require.NoError(t, err)
	return fb, svc
}

func signedInRequest(t *testing.T, sm *scs.SessionManager, method, target string) *http.Request {
	t.Helper()
	seed := httptest.NewRecorder()
	sm.LoadAndSave(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		require.NoError(t, session.SaveAuth(sm, r, api.AuthResponse{
			Token: "token", RefreshToken: "refresh", ExpiresIn: 3600,
			UserId: uuid.New(), Username: "norviq", Email: openapi_types.Email("user@example.com"),
		}))
	})).ServeHTTP(seed, httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/seed", http.NoBody))
	req := httptest.NewRequestWithContext(context.Background(), method, target, http.NoBody)
	for _, c := range seed.Result().Cookies() {
		req.AddCookie(c)
	}
	return req
}

func TestBudgetPageRecordsFunnelStep(t *testing.T) {
	t.Parallel()
	fb, svc := newFunnelBackend(t)
	sm := scs.New()
	sm.Lifetime = time.Hour
	h := NewOnboardingHandler(&Deps{Session: sm, Config: &config.Config{}, API: svc})

	rec := httptest.NewRecorder()
	sm.LoadAndSave(http.HandlerFunc(h.Budget)).ServeHTTP(rec, signedInRequest(t, sm, http.MethodGet, "/onboarding/budget"))

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, fb.patches, map[string]any{"funnelStep": "budget"})
}

func TestCompleteRecordsFunnelCompletion(t *testing.T) {
	t.Parallel()
	fb, svc := newFunnelBackend(t)
	sm := scs.New()
	sm.Lifetime = time.Hour
	h := NewOnboardingHandler(&Deps{Session: sm, Config: &config.Config{}, API: svc})

	rec := httptest.NewRecorder()
	sm.LoadAndSave(http.HandlerFunc(h.Complete)).ServeHTTP(rec, signedInRequest(t, sm, http.MethodPost, "/onboarding/complete"))

	assert.Equal(t, http.StatusSeeOther, rec.Code)
	assert.Contains(t, fb.patches, map[string]any{"funnelCompleted": true})
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `go test ./internal/onboarding/ ./internal/handlers/ -run 'Resume|FunnelPath|RecordsFunnel' -count=1`
Expected: the build fails with "undefined: Resume" and "undefined: FunnelPath".

- [ ] **Step 3: Write the API calls** in `internal/api/onboarding.go`

```go
package api

import (
	"context"
	"net/http"
	"time"
)

// OnboardingProgress mirrors OnboardingStateDTO in norviq-shared; the contract
// is norviq-shared/docs/guided-start.md. Hand-written like dca_capacity.go so
// the gate does not depend on codegen output names.
type OnboardingProgress struct {
	FunnelStep             *string    `json:"funnelStep"`
	FunnelCompletedAt      *time.Time `json:"funnelCompletedAt"`
	AddHoldingCompleted    bool       `json:"addHoldingCompleted"`
	SetBudgetCompleted     bool       `json:"setBudgetCompleted"`
	SetGoalCompleted       bool       `json:"setGoalCompleted"`
	GuidedStartDismissedAt *time.Time `json:"guidedStartDismissedAt"`
}

// OnboardingProgressPatch carries only the fields a client may write.
type OnboardingProgressPatch struct {
	FunnelStep           *string `json:"funnelStep,omitempty"`
	FunnelCompleted      *bool   `json:"funnelCompleted,omitempty"`
	GuidedStartDismissed *bool   `json:"guidedStartDismissed,omitempty"`
}

func (s *Service) GetOnboardingProgress(ctx context.Context, editors ...RequestEditorFn) (*OnboardingProgress, error) {
	var out OnboardingProgress
	if err := s.DoJSON(ctx, http.MethodGet, "/v1/onboarding", nil, &out, editors...); err != nil {
		return nil, err
	}
	return &out, nil
}

func (s *Service) PatchOnboardingProgress(ctx context.Context, patch OnboardingProgressPatch, editors ...RequestEditorFn) (*OnboardingProgress, error) {
	var out OnboardingProgress
	if err := s.DoJSON(ctx, http.MethodPatch, "/v1/onboarding", patch, &out, editors...); err != nil {
		return nil, err
	}
	return &out, nil
}
```

- [ ] **Step 4: Rewrite the gate** in `internal/onboarding/gate.go`

Replace `Needs` and `PostAuthRedirect` (keep `HasHoldings` and `SafeNextPath` unchanged), and add `"time"` to the imports:

```go
// gateTimeout bounds the one backend read the gate makes. DoJSON's client has
// no timeout of its own, and this runs in front of every gated page until the
// funnel is finished.
const gateTimeout = 3 * time.Second

// Resume reports whether the signed-in user still owes the onboarding funnel
// and, if so, the page to resume on. The backend row is the authority; the
// session only caches completion, so a finished user costs no backend call.
func Resume(ctx context.Context, sm *scs.SessionManager, r *http.Request, svc *api.Service, editor api.RequestEditorFn) (string, bool) {
	if session.IsOnboardingComplete(sm, r) {
		return "", false
	}
	// Fail closed: without a confirmed finished funnel the user stays in it.
	if svc == nil {
		return "/onboarding", true
	}
	ctx, cancel := context.WithTimeout(ctx, gateTimeout)
	defer cancel()
	progress, err := svc.GetOnboardingProgress(ctx, editor)
	if err != nil {
		slog.Warn("onboarding gate: could not read onboarding progress", "error", err)
		return "/onboarding", true
	}
	if progress.FunnelCompletedAt != nil {
		session.MarkOnboardingComplete(sm, r)
		return "", false
	}
	step := ""
	if progress.FunnelStep != nil {
		step = *progress.FunnelStep
	}
	return FunnelPath(step), true
}

func Needs(ctx context.Context, sm *scs.SessionManager, r *http.Request, svc *api.Service, editor api.RequestEditorFn) bool {
	_, needs := Resume(ctx, sm, r, svc, editor)
	return needs
}

// FunnelPath maps a stored funnel step to its page.
func FunnelPath(step string) string {
	switch step {
	case "questionnaire":
		return "/onboarding/questionnaire"
	case "paywall":
		return "/onboarding/paywall"
	case "import":
		return "/onboarding/import"
	case "budget":
		return "/onboarding/budget"
	default:
		return "/onboarding"
	}
}

func PostAuthRedirect(
	ctx context.Context,
	sm *scs.SessionManager,
	r *http.Request,
	svc *api.Service,
	editor api.RequestEditorFn,
) string {
	if session.RequiresOnboardingQuestionnaire(sm, r) {
		return "/onboarding/questionnaire"
	}
	if session.RequiresOnboardingPaywall(sm, r) {
		return "/onboarding/paywall"
	}
	if path, needs := Resume(ctx, sm, r, svc, editor); needs {
		return path
	}
	if next := SafeNextPath(r); next != "" {
		return next
	}
	return "/dashboard"
}
```

- [ ] **Step 5: Update the callers to pass the service**

1. In `internal/middleware/onboarding.go` `RequireOnboardingComplete`, replace the `var client … onboarding.Needs(...)` block with:
   ```go
   			if onboarding.Needs(r.Context(), sm, r, apiService, BearerEditor(sm, r)) {
   				http.Redirect(w, r, "/onboarding", http.StatusSeeOther)
   				return
   			}
   ```
2. In `internal/middleware/auth.go` `RedirectIfAuthenticated`, delete the `var client …` lines and call:
   ```go
   				dest := onboarding.PostAuthRedirect(r.Context(), sm, r, apiService, BearerEditor(sm, r))
   ```
3. Replace the body of `internal/handlers/onboarding_gate.go` `PostAuthRedirectPath` with:
   ```go
   	return onboarding.PostAuthRedirect(r.Context(), h.Session, r, h.API, middleware.BearerEditor(h.Session, r))
   ```
4. In `internal/handlers/onboarding.go` `guardInProgress`, replace `if h.deps.API == nil || h.deps.API.Client == nil {` with `if h.deps.API == nil {`, and change the `pkgonboarding.Needs(` call so its fourth argument is `h.deps.API`.

Run `go build ./...` and fix any remaining call site the compiler names. They all take the same change: `client` becomes `svc`.

- [ ] **Step 6: Record funnel progress in the onboarding handlers**

Add to `internal/handlers/onboarding.go`:

```go
// recordFunnelStep stores where the user is, so an unfinished funnel resumes
// on any device. Best-effort: a failed write costs a resume, not the page.
func (h *OnboardingHandler) recordFunnelStep(r *http.Request, step string) {
	if h.deps.API == nil {
		return
	}
	if _, err := h.deps.API.PatchOnboardingProgress(r.Context(), api.OnboardingProgressPatch{FunnelStep: &step}, middleware.BearerEditor(h.deps.Session, r)); err != nil {
		slog.Warn("onboarding: record funnel step", "step", step, "error", err)
	}
}

func (h *OnboardingHandler) recordFunnelComplete(r *http.Request) {
	if h.deps.API == nil {
		return
	}
	done := true
	if _, err := h.deps.API.PatchOnboardingProgress(r.Context(), api.OnboardingProgressPatch{FunnelCompleted: &done}, middleware.BearerEditor(h.deps.Session, r)); err != nil {
		slog.Warn("onboarding: record funnel completion", "error", err)
	}
}
```

Then add these calls. For handlers that call `guardInProgress`, put the call after the guard's `return` check and before rendering.

| Handler | Call |
|---|---|
| `Questionnaire` | `h.recordFunnelStep(r, "questionnaire")` |
| `Paywall` | `h.recordFunnelStep(r, "paywall")` |
| `Welcome` | `h.recordFunnelStep(r, "welcome")` |
| `ImportMenu` | `h.recordFunnelStep(r, "import")` |
| `Budget` | `h.recordFunnelStep(r, "budget")` |
| `BudgetSubmit` | `h.recordFunnelComplete(r)` directly before `session.MarkOnboardingComplete(h.deps.Session, r)` |
| `Skip`, in `case "budget", "all":` | `h.recordFunnelComplete(r)` directly before `session.MarkOnboardingComplete(...)` |
| `Complete` | `h.recordFunnelComplete(r)` directly before `session.MarkOnboardingComplete(...)` |

- [ ] **Step 7: Run the tests and fix the existing tests the gate change breaks**

Run: `go test ./... -count=1`
Expected: the new tests pass.

Some existing tests may fail because a stub backend served `/v1/stocks` for the gate's `HasHoldings`. Find them with `grep -rln 'v1/stocks' internal --include=*_test.go`. In each stub that feeds the gate, answer `/v1/onboarding` with a finished funnel instead:

```go
		case "/v1/onboarding":
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"funnelStep":"done","funnelCompletedAt":"2026-01-01T00:00:00Z","addHoldingCompleted":true,"setBudgetCompleted":true,"setGoalCompleted":true}`))
```

Tests that pass `&api.Service{}` still fail closed as before, because the request to an empty base URL errors.

- [ ] **Step 8: Commit**

```bash
git add internal/api/onboarding.go internal/onboarding internal/middleware internal/handlers
git commit -m "feat(onboarding): resume the web funnel from server-side progress"
```

---

### Task 5: Web guided-start rules (pure Go)

**Files:**
- Create: `internal/guide/guide.go`
- Test: `internal/guide/guide_test.go`

**Interfaces:**
- Consumes: `api.OnboardingProgress`.
- Produces, in package `guide`:
  - `type Step string`, with constants `AddHolding`, `SetBudget`, `SetGoal`, and `var Steps []Step`.
  - Methods on `Step`: `Valid() bool`, `Title() string`, `Line() string`, `Target() string`, `Path() string`, `Done(api.OnboardingProgress) bool`.
  - `type Progress struct{ Done map[Step]bool; Next Step; Count int }`, with `ProgressOf(*api.OnboardingProgress) Progress` and `(Progress) AllDone() bool`.
  - `Visible(p *api.OnboardingProgress, showCompleted bool) bool`.
  - `Resolve(requested Step, p *api.OnboardingProgress) (Step, bool)`.
  - `PollDelay(attempt int) time.Duration`.
  - `const StepTimeout = 5 * time.Minute`, plus `Headline`, `Completion`, `SkipLabel`, `ProgressLabel(int) string`, `DismissFailed`.

- [ ] **Step 1: Write the failing test**

```go
package guide

import (
	"testing"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/stretchr/testify/assert"
)

var finished = time.Date(2026, 9, 24, 10, 0, 0, 0, time.UTC)

func progress(holding, budget, goal bool) *api.OnboardingProgress {
	return &api.OnboardingProgress{FunnelCompletedAt: &finished, AddHoldingCompleted: holding, SetBudgetCompleted: budget, SetGoalCompleted: goal}
}

func TestVisibility(t *testing.T) {
	t.Parallel()
	dismissed := progress(false, false, false)
	dismissed.GuidedStartDismissedAt = &finished
	inFunnel := progress(false, false, false)
	inFunnel.FunnelCompletedAt = nil

	assert.False(t, Visible(nil, false), "not loaded renders nothing")
	assert.False(t, Visible(inFunnel, false), "the funnel comes first")
	assert.True(t, Visible(progress(true, false, false), false))
	assert.False(t, Visible(dismissed, false))
	assert.False(t, Visible(progress(true, true, true), false), "finished wizard hides")
	assert.True(t, Visible(progress(true, true, true), true), "unless reopened this session")
}

func TestProgressAndResolve(t *testing.T) {
	t.Parallel()
	p := ProgressOf(progress(true, false, false))
	assert.Equal(t, 1, p.Count)
	assert.Equal(t, SetBudget, p.Next)
	assert.False(t, p.AllDone())

	step, ok := Resolve(AddHolding, progress(true, false, false))
	assert.True(t, ok)
	assert.Equal(t, SetBudget, step, "a done step skips ahead to the first open one")

	_, ok = Resolve(SetGoal, progress(true, true, true))
	assert.False(t, ok, "nothing left to start")
}

func TestPollDelaySchedule(t *testing.T) {
	t.Parallel()
	want := []time.Duration{time.Second, 2 * time.Second, 4 * time.Second, 8 * time.Second, 10 * time.Second, 10 * time.Second}
	for attempt, d := range want {
		assert.Equal(t, d, PollDelay(attempt), "attempt %d", attempt)
	}
}

func TestStepVocabulary(t *testing.T) {
	t.Parallel()
	assert.Equal(t, []Step{"add_holding", "set_budget", "set_goal"}, Steps)
	assert.Equal(t, "holding-add", AddHolding.Target())
	assert.Equal(t, "/expenses", SetBudget.Path())
	assert.Equal(t, "/goals", SetGoal.Path())
	assert.False(t, Step("view_insights").Valid())
	assert.Equal(t, "2 of 3", ProgressLabel(2))
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `go test ./internal/guide/ -count=1`
Expected: the build fails with "no non-test Go files".

- [ ] **Step 3: Write `internal/guide/guide.go`**

```go
// Package guide holds the guided-start rules shared by the dashboard card and
// the step layer. Contract: norviq-shared/docs/guided-start.md.
package guide

import (
	"strconv"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
)

type Step string

const (
	AddHolding Step = "add_holding"
	SetBudget  Step = "set_budget"
	SetGoal    Step = "set_goal"
)

var Steps = []Step{AddHolding, SetBudget, SetGoal}

const (
	Headline      = "Get started with Norviq"
	Completion    = "You're set up. Everything else builds on these three."
	SkipLabel     = "Skip"
	DismissFailed = "Couldn't hide that just now — try again in a moment."
	StepTimeout   = 5 * time.Minute
)

func ProgressLabel(done int) string {
	return strconv.Itoa(done) + " of " + strconv.Itoa(len(Steps))
}

func (s Step) Valid() bool {
	switch s {
	case AddHolding, SetBudget, SetGoal:
		return true
	}
	return false
}

func (s Step) Title() string {
	switch s {
	case AddHolding:
		return "Add a holding"
	case SetBudget:
		return "Set your budget"
	case SetGoal:
		return "Set a goal"
	}
	return ""
}

func (s Step) Line() string {
	switch s {
	case AddHolding:
		return "Add one stock or ETF you own."
	case SetBudget:
		return "Enter your monthly take-home pay."
	case SetGoal:
		return "Pick one thing you're saving for."
	}
	return ""
}

// Target is the data-guide value of the control the step teaches.
func (s Step) Target() string {
	switch s {
	case AddHolding:
		return "holding-add"
	case SetBudget:
		return "budget-salary"
	case SetGoal:
		return "goal-create"
	}
	return ""
}

// Path is the page the target lives on.
func (s Step) Path() string {
	switch s {
	case AddHolding:
		return "/portfolio"
	case SetBudget:
		return "/expenses"
	case SetGoal:
		return "/goals"
	}
	return "/dashboard"
}

func (s Step) Done(p api.OnboardingProgress) bool {
	switch s {
	case AddHolding:
		return p.AddHoldingCompleted
	case SetBudget:
		return p.SetBudgetCompleted
	case SetGoal:
		return p.SetGoalCompleted
	}
	return false
}

type Progress struct {
	Done  map[Step]bool
	Next  Step // "" when everything is done
	Count int
}

func (p Progress) AllDone() bool { return p.Next == "" }

func ProgressOf(p *api.OnboardingProgress) Progress {
	out := Progress{Done: map[Step]bool{}}
	for _, step := range Steps {
		done := p != nil && step.Done(*p)
		out.Done[step] = done
		if done {
			out.Count++
		} else if out.Next == "" {
			out.Next = step
		}
	}
	return out
}

// Visible is the card rule: loaded, funnel finished, not dismissed, not all
// done — except a finished wizard reopened through "Show me around" shows its
// completed card for the rest of that session.
func Visible(p *api.OnboardingProgress, showCompleted bool) bool {
	if p == nil || p.FunnelCompletedAt == nil || p.GuidedStartDismissedAt != nil {
		return false
	}
	if ProgressOf(p).AllDone() {
		return showCompleted
	}
	return true
}

// Resolve returns the step to open: the requested one unless it is already
// done, in which case the first open step, and false when none is left.
func Resolve(requested Step, p *api.OnboardingProgress) (Step, bool) {
	if p == nil || !requested.Done(*p) {
		return requested, true
	}
	next := ProgressOf(p).Next
	return next, next != ""
}

var pollBackoff = []time.Duration{time.Second, 2 * time.Second, 4 * time.Second, 8 * time.Second}

// PollDelay is the wait before poll number attempt (0-based): 1s, 2s, 4s, 8s,
// then every 10s.
func PollDelay(attempt int) time.Duration {
	if attempt >= 0 && attempt < len(pollBackoff) {
		return pollBackoff[attempt]
	}
	return 10 * time.Second
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `go test ./internal/guide/ -count=1`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add internal/guide
git commit -m "feat(guided-start): step, visibility and poll-schedule rules"
```

---

### Task 6: Web guided-start session state and handlers

**Files:**
- Create: `internal/session/guided_start.go`, `internal/session/guided_start_test.go`, `internal/handlers/guided_start.go`, `internal/handlers/guided_start_test.go`
- Modify: `internal/server/server.go`; the handlers `PortfolioCreatePosition`, `ExpensesSalarySubmit` and `FinancialGoalCreate` (the local-action notes)

**Interfaces:**
- Consumes: `guide.*` (Task 5), `api.Service` onboarding calls (Task 4), and the templ components from Task 7.
  - Task 7's components: `guidedstart.Card`, `guidedstart.Poller`, `guidedstart.StepDone`, `guidedstart.StepEnded`, `guidedstart.Dismissed`.
  - This task's handler tests assert on the markup those components render. Build Task 7's templ file before running Step 5 here, or do Tasks 6 and 7 in one sitting.
- Produces:
  - session helpers: `StartGuidedStep`, `ActiveGuidedStep`, `MarkGuidedStepAnnounced`, `NoteGuidedAction`, `ClearGuidedStep`, `SetGuidedPendingSource`, `TakeGuidedPendingSource`, `MarkGuidedCardShown`, `SetGuidedShowCompleted`, `GuidedShowCompleted`, `MarkGuidedCompletedSent`
  - handlers: `(*AppHandler).GuidedStartStep`, `GuidedStartPoll`, `GuidedStartSkip`, `GuidedStartDismiss`, `ShowMeAround`
  - helpers: `(*AppHandler).loadGuidedProgress(r)`, `(*AppHandler).guidedCardVM(r, p, message) guidedstart.CardVM`

- [ ] **Step 1: Write the session helpers test** (`internal/session/guided_start_test.go`)

```go
package session

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/alexedwards/scs/v2"
	"github.com/stretchr/testify/assert"
)

func inSession(t *testing.T, fn func(sm *scs.SessionManager, r *http.Request)) {
	t.Helper()
	sm := scs.New()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/", http.NoBody)
	sm.LoadAndSave(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) { fn(sm, r) })).ServeHTTP(httptest.NewRecorder(), req)
}

func TestGuidedStepLifecycle(t *testing.T) {
	t.Parallel()
	inSession(t, func(sm *scs.SessionManager, r *http.Request) {
		_, ok := ActiveGuidedStep(sm, r)
		assert.False(t, ok)

		started := time.Date(2026, 9, 24, 10, 0, 0, 0, time.UTC)
		StartGuidedStep(sm, r, "set_goal", "settings", started)
		NoteGuidedAction(sm, r, "add_holding") // a different step: ignored
		step, ok := ActiveGuidedStep(sm, r)
		assert.True(t, ok)
		assert.Equal(t, GuidedStep{Step: "set_goal", StartedAt: started, Source: "settings"}, step)

		NoteGuidedAction(sm, r, "set_goal")
		MarkGuidedStepAnnounced(sm, r)
		step, _ = ActiveGuidedStep(sm, r)
		assert.True(t, step.Acted)
		assert.True(t, step.Announced)

		ClearGuidedStep(sm, r)
		_, ok = ActiveGuidedStep(sm, r)
		assert.False(t, ok)
	})
}

func TestGuidedOncePerSessionFlags(t *testing.T) {
	t.Parallel()
	inSession(t, func(sm *scs.SessionManager, r *http.Request) {
		assert.True(t, MarkGuidedCardShown(sm, r))
		assert.False(t, MarkGuidedCardShown(sm, r))
		assert.True(t, MarkGuidedCompletedSent(sm, r))
		assert.False(t, MarkGuidedCompletedSent(sm, r))

		SetGuidedPendingSource(sm, r, "settings")
		assert.Equal(t, "settings", TakeGuidedPendingSource(sm, r))
		assert.Equal(t, "", TakeGuidedPendingSource(sm, r))
	})
}
```

- [ ] **Step 2: Write `internal/session/guided_start.go`**

```go
package session

import (
	"net/http"
	"time"

	"github.com/alexedwards/scs/v2"
)

// The active guided-start step lives in the session rather than the URL so
// it survives the user's own form submit and the redirect after it.
const (
	KeyGuidedStep          = "guidedStartStep"
	KeyGuidedStepStartedAt = "guidedStartStepStartedAt"
	KeyGuidedStepSource    = "guidedStartStepSource"
	KeyGuidedStepAnnounced = "guidedStartStepAnnounced"
	KeyGuidedStepActed     = "guidedStartStepActed"
	KeyGuidedPendingSource = "guidedStartPendingSource"
	KeyGuidedCardShown     = "guidedStartCardShown"
	KeyGuidedShowCompleted = "guidedStartShowCompleted"
	KeyGuidedCompletedSent = "guidedStartCompletedSent"
)

type GuidedStep struct {
	Step      string
	StartedAt time.Time
	Source    string
	Announced bool
	Acted     bool
}

func StartGuidedStep(sm *scs.SessionManager, r *http.Request, step, source string, now time.Time) {
	sm.Put(r.Context(), KeyGuidedStep, step)
	sm.Put(r.Context(), KeyGuidedStepStartedAt, now)
	sm.Put(r.Context(), KeyGuidedStepSource, source)
	sm.Put(r.Context(), KeyGuidedStepAnnounced, false)
	sm.Put(r.Context(), KeyGuidedStepActed, false)
}

func ActiveGuidedStep(sm *scs.SessionManager, r *http.Request) (GuidedStep, bool) {
	step := sm.GetString(r.Context(), KeyGuidedStep)
	if step == "" {
		return GuidedStep{}, false
	}
	return GuidedStep{
		Step:      step,
		StartedAt: sm.GetTime(r.Context(), KeyGuidedStepStartedAt),
		Source:    sm.GetString(r.Context(), KeyGuidedStepSource),
		Announced: sm.GetBool(r.Context(), KeyGuidedStepAnnounced),
		Acted:     sm.GetBool(r.Context(), KeyGuidedStepActed),
	}, true
}

func MarkGuidedStepAnnounced(sm *scs.SessionManager, r *http.Request) {
	sm.Put(r.Context(), KeyGuidedStepAnnounced, true)
}

// NoteGuidedAction records that the user did the open step's action here, so
// its completion is not reported as having happened on another device.
func NoteGuidedAction(sm *scs.SessionManager, r *http.Request, step string) {
	if sm.GetString(r.Context(), KeyGuidedStep) == step {
		sm.Put(r.Context(), KeyGuidedStepActed, true)
	}
}

func ClearGuidedStep(sm *scs.SessionManager, r *http.Request) {
	for _, key := range []string{KeyGuidedStep, KeyGuidedStepStartedAt, KeyGuidedStepSource, KeyGuidedStepAnnounced, KeyGuidedStepActed} {
		sm.Remove(r.Context(), key)
	}
}

func SetGuidedPendingSource(sm *scs.SessionManager, r *http.Request, source string) {
	sm.Put(r.Context(), KeyGuidedPendingSource, source)
}

func TakeGuidedPendingSource(sm *scs.SessionManager, r *http.Request) string {
	return sm.PopString(r.Context(), KeyGuidedPendingSource)
}

// MarkGuidedCardShown reports true the first time in a session.
func MarkGuidedCardShown(sm *scs.SessionManager, r *http.Request) bool {
	if sm.GetBool(r.Context(), KeyGuidedCardShown) {
		return false
	}
	sm.Put(r.Context(), KeyGuidedCardShown, true)
	return true
}

func SetGuidedShowCompleted(sm *scs.SessionManager, r *http.Request) {
	sm.Put(r.Context(), KeyGuidedShowCompleted, true)
}

func GuidedShowCompleted(sm *scs.SessionManager, r *http.Request) bool {
	return sm.GetBool(r.Context(), KeyGuidedShowCompleted)
}

// MarkGuidedCompletedSent reports true the first time in a session.
func MarkGuidedCompletedSent(sm *scs.SessionManager, r *http.Request) bool {
	if sm.GetBool(r.Context(), KeyGuidedCompletedSent) {
		return false
	}
	sm.Put(r.Context(), KeyGuidedCompletedSent, true)
	return true
}
```

Run: `go test ./internal/session/ -run Guided -count=1`
Expected: PASS.

- [ ] **Step 3: Write the failing handler tests** (`internal/handlers/guided_start_test.go`)

```go
package handlers

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/FinancePlanner/StockPlanWeb/internal/config"
	"github.com/FinancePlanner/StockPlanWeb/internal/session"
	"github.com/alexedwards/scs/v2"
	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	progressNothingDone = `{"funnelStep":"done","funnelCompletedAt":"2026-09-01T00:00:00Z","addHoldingCompleted":false,"setBudgetCompleted":false,"setGoalCompleted":false,"guidedStartDismissedAt":null}`
	progressHoldingDone = `{"funnelStep":"done","funnelCompletedAt":"2026-09-01T00:00:00Z","addHoldingCompleted":true,"setBudgetCompleted":false,"setGoalCompleted":false,"guidedStartDismissedAt":null}`
	progressAllDone     = `{"funnelStep":"done","funnelCompletedAt":"2026-09-01T00:00:00Z","addHoldingCompleted":true,"setBudgetCompleted":true,"setGoalCompleted":true,"guidedStartDismissedAt":null}`
)

// guidedEnv is an AppHandler wired to a stub backend, with one browser
// session carried across requests.
type guidedEnv struct {
	t        *testing.T
	sm       *scs.SessionManager
	h        *AppHandler
	cookies  []*http.Cookie
	mu       sync.Mutex
	progress string
	patchErr bool
	patches  []string
}

func newGuidedEnv(t *testing.T, progress string) *guidedEnv {
	t.Helper()
	e := &guidedEnv{t: t, progress: progress, sm: scs.New()}
	e.sm.Lifetime = time.Hour
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "/v1/onboarding", r.URL.Path)
		e.mu.Lock()
		defer e.mu.Unlock()
		if r.Method == http.MethodPatch {
			raw, _ := io.ReadAll(r.Body)
			e.patches = append(e.patches, string(raw))
			if e.patchErr {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(e.progress))
	}))
	t.Cleanup(backend.Close)
	svc, err := api.NewService(backend.URL)
	require.NoError(t, err)
	e.h = NewAppHandler(&Deps{Session: e.sm, Config: &config.Config{}, API: svc})
	e.run(func(r *http.Request) {
		require.NoError(t, session.SaveAuth(e.sm, r, api.AuthResponse{
			Token: "token", RefreshToken: "refresh", ExpiresIn: 3600,
			UserId: uuid.New(), Username: "norviq", Email: openapi_types.Email("user@example.com"),
		}))
		session.MarkOnboardingComplete(e.sm, r)
	})
	return e
}

func (e *guidedEnv) setProgress(p string) {
	e.mu.Lock()
	e.progress = p
	e.mu.Unlock()
}

// run executes fn inside the carried session.
func (e *guidedEnv) run(fn func(r *http.Request)) {
	e.do(func(_ http.ResponseWriter, r *http.Request) { fn(r) }, http.MethodGet, "/")
}

func (e *guidedEnv) do(handler http.HandlerFunc, method, target string) *httptest.ResponseRecorder {
	req := httptest.NewRequestWithContext(context.Background(), method, target, http.NoBody)
	for _, c := range e.cookies {
		req.AddCookie(c)
	}
	rec := httptest.NewRecorder()
	e.sm.LoadAndSave(handler).ServeHTTP(rec, req)
	if fresh := rec.Result().Cookies(); len(fresh) > 0 {
		e.cookies = fresh
	}
	return rec
}

func TestGuidedStartStepRedirectsToTargetPage(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	rec := e.do(e.h.GuidedStartStep, http.MethodGet, "/guided-start/start?step=set_budget")
	assert.Equal(t, http.StatusSeeOther, rec.Code)
	assert.Equal(t, "/expenses", rec.Header().Get("Location"))
	e.run(func(r *http.Request) {
		step, ok := session.ActiveGuidedStep(e.sm, r)
		assert.True(t, ok)
		assert.Equal(t, "set_budget", step.Step)
		assert.Equal(t, "auto", step.Source)
	})
}

func TestGuidedStartStepSkipsAheadPastDoneStep(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressHoldingDone)
	rec := e.do(e.h.GuidedStartStep, http.MethodGet, "/guided-start/start?step=add_holding")
	assert.Equal(t, "/expenses", rec.Header().Get("Location"))
}

func TestGuidedStartPollKeepsPollingWithBackoff(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	e.do(e.h.GuidedStartStep, http.MethodGet, "/guided-start/start?step=add_holding")
	rec := e.do(e.h.GuidedStartPoll, http.MethodGet, "/guided-start/poll?attempt=1")
	assert.Contains(t, rec.Body.String(), `hx-trigger="load delay:4s"`)
	assert.Contains(t, rec.Body.String(), `attempt=2`)
}

func TestGuidedStartPollCompletesStep(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	e.do(e.h.GuidedStartStep, http.MethodGet, "/guided-start/start?step=add_holding")
	e.run(func(r *http.Request) { session.NoteGuidedAction(e.sm, r, "add_holding") })
	e.setProgress(progressHoldingDone)

	body := e.do(e.h.GuidedStartPoll, http.MethodGet, "/guided-start/poll?attempt=0").Body.String()
	assert.Contains(t, body, `id="guided-step-layer"`)
	assert.Contains(t, body, "hx-swap-oob")
	assert.Contains(t, body, "guided_start_step_completed")
	assert.Contains(t, body, "completed_elsewhere: false")
	e.run(func(r *http.Request) {
		_, ok := session.ActiveGuidedStep(e.sm, r)
		assert.False(t, ok)
	})
}

func TestGuidedStartPollTimesOut(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	e.run(func(r *http.Request) {
		session.StartGuidedStep(e.sm, r, "set_goal", "auto", time.Now().Add(-6*time.Minute))
	})
	body := e.do(e.h.GuidedStartPoll, http.MethodGet, "/guided-start/poll?attempt=9").Body.String()
	assert.Contains(t, body, "guided_start_step_timed_out")
	e.run(func(r *http.Request) {
		_, ok := session.ActiveGuidedStep(e.sm, r)
		assert.False(t, ok)
	})
}

func TestGuidedStartSkipEndsStep(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	e.do(e.h.GuidedStartStep, http.MethodGet, "/guided-start/start?step=add_holding")
	body := e.do(e.h.GuidedStartSkip, http.MethodPost, "/guided-start/skip").Body.String()
	assert.Contains(t, body, "guided_start_step_skipped")
	e.run(func(r *http.Request) {
		_, ok := session.ActiveGuidedStep(e.sm, r)
		assert.False(t, ok)
	})
}

func TestGuidedStartDismissPatchesAndRestoresOnFailure(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	ok := e.do(e.h.GuidedStartDismiss, http.MethodPost, "/guided-start/dismiss")
	assert.Contains(t, ok.Body.String(), "guided_start_dismissed")
	assert.Equal(t, []string{`{"guidedStartDismissed":true}`}, e.patches)

	e.patchErr = true
	failed := e.do(e.h.GuidedStartDismiss, http.MethodPost, "/guided-start/dismiss")
	assert.Contains(t, failed.Body.String(), `id="guided-start-card"`)
	assert.Contains(t, failed.Body.String(), "Couldn&#39;t hide that just now")
}

func TestShowMeAroundReopensFinishedWizardForSession(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressAllDone)
	rec := e.do(e.h.ShowMeAround, http.MethodPost, "/settings/show-me-around")
	assert.Equal(t, "/dashboard", rec.Header().Get("Location"))
	assert.Equal(t, []string{`{"guidedStartDismissed":false}`}, e.patches)
	e.run(func(r *http.Request) {
		assert.True(t, session.GuidedShowCompleted(e.sm, r))
		assert.Equal(t, "settings", session.TakeGuidedPendingSource(e.sm, r))
	})
}

func TestGuidedCardVMFiresCardShownOnce(t *testing.T) {
	t.Parallel()
	e := newGuidedEnv(t, progressNothingDone)
	var first, second bool
	e.run(func(r *http.Request) {
		p := e.h.loadGuidedProgress(r)
		first = e.h.guidedCardVM(r, p, "").FireCardShown
		second = e.h.guidedCardVM(r, p, "").FireCardShown
	})
	assert.True(t, first)
	assert.False(t, second)
}
```

- [ ] **Step 4: Write `internal/handlers/guided_start.go`**

```go
package handlers

import (
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/FinancePlanner/StockPlanWeb/internal/guide"
	"github.com/FinancePlanner/StockPlanWeb/internal/middleware"
	"github.com/FinancePlanner/StockPlanWeb/internal/pages/guidedstart"
	"github.com/FinancePlanner/StockPlanWeb/internal/session"
	"github.com/a-h/templ"
)

// guidedNow is swapped in tests that need a fixed clock.
var guidedNow = time.Now

func (h *AppHandler) loadGuidedProgress(r *http.Request) *api.OnboardingProgress {
	if h.deps.API == nil {
		return nil
	}
	p, err := h.deps.API.GetOnboardingProgress(r.Context(), middleware.BearerEditor(h.deps.Session, r))
	if err != nil {
		slog.Warn("guided start: read progress", "error", err)
		return nil
	}
	return p
}

// guidedCardVM builds the dashboard card. Unloaded progress renders nothing:
// no flash, and no error box on the dashboard for a side feature.
func (h *AppHandler) guidedCardVM(r *http.Request, p *api.OnboardingProgress, message string) guidedstart.CardVM {
	if !guide.Visible(p, session.GuidedShowCompleted(h.deps.Session, r)) {
		return guidedstart.CardVM{}
	}
	progress := guide.ProgressOf(p)
	vm := guidedstart.CardVM{Visible: true, Progress: progress, Message: message}
	vm.FireCardShown = session.MarkGuidedCardShown(h.deps.Session, r)
	if progress.AllDone() {
		vm.FireCompleted = session.MarkGuidedCompletedSent(h.deps.Session, r)
	}
	return vm
}

// withGuidedStepLayer adds the step layer to any app page while a step is
// open. It reads only the session, so pages pay no backend call for it.
func (h *AppHandler) withGuidedStepLayer(r *http.Request, content templ.Component) templ.Component {
	active, ok := session.ActiveGuidedStep(h.deps.Session, r)
	if !ok {
		return content
	}
	step := guide.Step(active.Step)
	if !step.Valid() {
		session.ClearGuidedStep(h.deps.Session, r)
		return content
	}
	announce := !active.Announced
	if announce {
		session.MarkGuidedStepAnnounced(h.deps.Session, r)
	}
	return guidedstart.WithStepLayer(content, guidedstart.LayerVM{Step: step, Source: active.Source, Announce: announce})
}

func (h *AppHandler) GuidedStartStep(w http.ResponseWriter, r *http.Request) {
	requested := guide.Step(r.URL.Query().Get("step"))
	if !requested.Valid() {
		http.Redirect(w, r, "/dashboard", http.StatusSeeOther)
		return
	}
	step, ok := guide.Resolve(requested, h.loadGuidedProgress(r))
	if !ok {
		session.ClearGuidedStep(h.deps.Session, r)
		session.SetGuidedShowCompleted(h.deps.Session, r)
		http.Redirect(w, r, "/dashboard", http.StatusSeeOther)
		return
	}
	source := session.TakeGuidedPendingSource(h.deps.Session, r)
	if source == "" {
		source = "auto"
	}
	session.StartGuidedStep(h.deps.Session, r, string(step), source, guidedNow())
	http.Redirect(w, r, step.Path(), http.StatusSeeOther)
}

func (h *AppHandler) GuidedStartPoll(w http.ResponseWriter, r *http.Request) {
	setHTMLContentType(w)
	active, ok := session.ActiveGuidedStep(h.deps.Session, r)
	if !ok {
		return // empty body: the poller swaps itself out
	}
	step := guide.Step(active.Step)
	elapsed := guidedNow().Sub(active.StartedAt)
	outcome := guidedstart.OutcomeVM{Step: step, ElapsedMs: elapsed.Milliseconds(), Elsewhere: !active.Acted}

	if p := h.loadGuidedProgress(r); p != nil && step.Done(*p) {
		session.ClearGuidedStep(h.deps.Session, r)
		if guide.ProgressOf(p).AllDone() {
			session.SetGuidedShowCompleted(h.deps.Session, r)
		}
		h.renderFragment(w, r, guidedstart.StepDone(outcome))
		return
	}
	if elapsed >= guide.StepTimeout {
		session.ClearGuidedStep(h.deps.Session, r)
		h.renderFragment(w, r, guidedstart.StepEnded(outcome, "guided_start_step_timed_out"))
		return
	}
	attempt, _ := strconv.Atoi(r.URL.Query().Get("attempt"))
	h.renderFragment(w, r, guidedstart.Poller(attempt+1))
}

func (h *AppHandler) GuidedStartSkip(w http.ResponseWriter, r *http.Request) {
	setHTMLContentType(w)
	active, ok := session.ActiveGuidedStep(h.deps.Session, r)
	if !ok {
		return
	}
	session.ClearGuidedStep(h.deps.Session, r)
	outcome := guidedstart.OutcomeVM{Step: guide.Step(active.Step), ElapsedMs: guidedNow().Sub(active.StartedAt).Milliseconds()}
	h.renderFragment(w, r, guidedstart.StepEnded(outcome, "guided_start_step_skipped"))
}

func (h *AppHandler) GuidedStartDismiss(w http.ResponseWriter, r *http.Request) {
	setHTMLContentType(w)
	dismissed := true
	if h.deps.API != nil {
		if _, err := h.deps.API.PatchOnboardingProgress(r.Context(), api.OnboardingProgressPatch{GuidedStartDismissed: &dismissed}, middleware.BearerEditor(h.deps.Session, r)); err == nil {
			h.renderFragment(w, r, guidedstart.Dismissed())
			return
		} else {
			slog.Warn("guided start: dismiss", "error", err)
		}
	}
	// The card was hidden optimistically; put it back and say why.
	h.renderFragment(w, r, guidedstart.Card(h.guidedCardVM(r, h.loadGuidedProgress(r), guide.DismissFailed)))
}

func (h *AppHandler) ShowMeAround(w http.ResponseWriter, r *http.Request) {
	shown := false
	var progress *api.OnboardingProgress
	if h.deps.API != nil {
		p, err := h.deps.API.PatchOnboardingProgress(r.Context(), api.OnboardingProgressPatch{GuidedStartDismissed: &shown}, middleware.BearerEditor(h.deps.Session, r))
		if err != nil {
			slog.Warn("guided start: show me around", "error", err)
		}
		progress = p
	}
	if progress != nil && guide.ProgressOf(progress).AllDone() {
		session.SetGuidedShowCompleted(h.deps.Session, r)
	}
	session.SetGuidedPendingSource(h.deps.Session, r, "settings")
	_ = session.SetPostHogCaptureOnce(h.deps.Session, r, "guided_start_reopened", nil)
	http.Redirect(w, r, "/dashboard", http.StatusSeeOther)
}

func (h *AppHandler) renderFragment(w http.ResponseWriter, r *http.Request, c templ.Component) {
	if err := c.Render(r.Context(), w); err != nil {
		slog.Error("guided start: render", "error", err)
		http.Error(w, "Failed to render", http.StatusInternalServerError)
	}
}
```

- [ ] **Step 5: Register the routes and add the local-action notes**

In `internal/server/server.go`, inside the gated group next to `r.Get("/dashboard", appHandler.Dashboard)`:

```go
		r.Get("/guided-start/start", appHandler.GuidedStartStep)
		r.Get("/guided-start/poll", appHandler.GuidedStartPoll)
		r.Post("/guided-start/skip", appHandler.GuidedStartSkip)
		r.Post("/guided-start/dismiss", appHandler.GuidedStartDismiss)
		r.Post("/settings/show-me-around", appHandler.ShowMeAround)
```

Then add one line to each target handler, right where it has confirmed the backend write succeeded (before its success redirect or render):
- `PortfolioCreatePosition`: `session.NoteGuidedAction(h.deps.Session, r, "add_holding")`
- `ExpensesSalarySubmit`: `session.NoteGuidedAction(h.deps.Session, r, "set_budget")`
- `FinancialGoalCreate`: `session.NoteGuidedAction(h.deps.Session, r, "set_goal")`, directly before `h.redirectFinancialGoals(w, r, "Financial goal created.", "")`

- [ ] **Step 6: Run the tests**

Run `go test ./internal/handlers/ -run 'Guided|ShowMeAround' -count=1` after Task 7, Step 3 exists. Expected: PASS.

- [ ] **Step 7: Commit** (together with Task 7 if done in one sitting)

```bash
git add internal/session/guided_start*.go internal/handlers/guided_start*.go internal/server/server.go internal/handlers/*.go
git commit -m "feat(guided-start): session-held active step, poll/skip/dismiss/show-me-around handlers"
```

---

### Task 7: Web guided-start UI (card, step layer, spotlight, targets)

**Files:**
- Create: `internal/pages/guidedstart/guidedstart.templ`, `internal/pages/guidedstart/guidedstart_test.go`, `internal/server/assets/guided-start.js`, `internal/server/assets/css/guided-start.css`
- Modify:
  - `internal/pages/dashboard/viewmodel.go`, `command_center.templ`, `pulse.templ`
  - `internal/handlers/app.go` (`renderShell`, `Dashboard`, `DashboardPulse`)
  - `internal/pages/portfolio/holdings.templ`, `internal/pages/expenses/planner.templ`, `internal/pages/goals/page.templ`
  - `internal/pages/settings/settings.templ`
  - `internal/server/assets/scripts.js`, `internal/server/assets/styles.css`

**Interfaces:**
- Consumes: `guide.*`.
- Produces, in package `guidedstart`:
  - types: `CardVM{Visible, Progress, Message, FireCardShown, FireCompleted}`, `LayerVM{Step, Source, Announce}`, `OutcomeVM{Step, ElapsedMs, Elsewhere}`
  - templ components: `Card(CardVM)`, `WithStepLayer(templ.Component, LayerVM)`, `StepLayer(LayerVM)`, `Poller(attempt int)`, `StepDone(OutcomeVM)`, `StepEnded(OutcomeVM, event string)`, `Dismissed()`
- Produces, in JS: `Alpine.data('guidedSpotlight', target => …)`

- [ ] **Step 1: Write the failing render test** (`internal/pages/guidedstart/guidedstart_test.go`)

```go
package guidedstart

import (
	"bytes"
	"context"
	"testing"
	"time"

	"github.com/FinancePlanner/StockPlanWeb/internal/api"
	"github.com/FinancePlanner/StockPlanWeb/internal/guide"
	"github.com/a-h/templ"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func render(t *testing.T, c templ.Component) string {
	t.Helper()
	var buf bytes.Buffer
	require.NoError(t, c.Render(context.Background(), &buf))
	return buf.String()
}

func TestCardRendersRowsProgressAndStartLinks(t *testing.T) {
	t.Parallel()
	done := time.Now()
	vm := CardVM{Visible: true, Progress: guide.ProgressOf(&api.OnboardingProgress{FunnelCompletedAt: &done, AddHoldingCompleted: true}), FireCardShown: true}
	html := render(t, Card(vm))
	assert.Contains(t, html, "Get started with Norviq")
	assert.Contains(t, html, "1 of 3")
	assert.Contains(t, html, `href="/guided-start/start?step=set_budget"`)
	assert.Contains(t, html, "guided_start_card_shown")
	assert.NotContains(t, html, "<button", "make check-controls forbids bare buttons")
}

func TestHiddenCardRendersNothing(t *testing.T) {
	t.Parallel()
	assert.Empty(t, render(t, Card(CardVM{})))
}

func TestStepLayerTargetsControlAndAnnouncesOnce(t *testing.T) {
	t.Parallel()
	html := render(t, StepLayer(LayerVM{Step: guide.SetGoal, Source: "settings", Announce: true}))
	assert.Contains(t, html, `guidedSpotlight(&#39;goal-create&#39;)`)
	assert.Contains(t, html, "Pick one thing you&#39;re saving for.")
	assert.Contains(t, html, "guided_start_step_started")
	assert.Contains(t, html, `hx-trigger="load delay:1s"`)
	quiet := render(t, StepLayer(LayerVM{Step: guide.SetGoal}))
	assert.NotContains(t, quiet, "guided_start_step_started")
}

func TestPollerEscalates(t *testing.T) {
	t.Parallel()
	assert.Contains(t, render(t, Poller(3)), `hx-trigger="load delay:8s"`)
	assert.Contains(t, render(t, Poller(7)), `hx-trigger="load delay:10s"`)
}
```

Also add to `internal/pages/dashboard/command_center_test.go` (it already has a render helper; reuse it):

```go
func TestGuidedCardReplacesAttentionPanel(t *testing.T) {
	t.Parallel()
	done := time.Now()
	vm := CommandCenterViewModel{}
	vm.GuidedStart = guidedstart.CardVM{Visible: true, Progress: guide.ProgressOf(&api.OnboardingProgress{FunnelCompletedAt: &done})}
	html := renderComponent(t, CommandCenterPage(vm))
	assert.Contains(t, html, `id="guided-start-card"`)
	assert.NotContains(t, html, "Finish setup to make this dashboard useful.")
}
```

If that file's render helper has a different name, use that name. Add imports for `guidedstart`, `guide`, `api` and `time` as needed.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `templ generate && go test ./internal/pages/guidedstart/ ./internal/pages/dashboard/ -count=1`
Expected: the build fails with "undefined: Card".

- [ ] **Step 3: Write `internal/pages/guidedstart/guidedstart.templ`**

```templ
package guidedstart

import (
	"strconv"

	"github.com/FinancePlanner/StockPlanWeb/internal/guide"
	"github.com/FinancePlanner/StockPlanWeb/internal/pages/components"
)

type CardVM struct {
	Visible       bool
	Progress      guide.Progress
	Message       string
	FireCardShown bool
	FireCompleted bool
}

type LayerVM struct {
	Step     guide.Step
	Source   string
	Announce bool
}

type OutcomeVM struct {
	Step      guide.Step
	ElapsedMs int64
	Elsewhere bool
}

func capture(event string, props string) string {
	return "window.norviqAnalytics?.capture('" + event + "', " + props + ")"
}

func (vm CardVM) initScript() string {
	script := ""
	if vm.FireCardShown {
		script += capture("guided_start_card_shown", "{}") + ";"
	}
	if vm.FireCompleted {
		script += capture("guided_start_completed", "{}") + ";"
	}
	return script
}

func (vm LayerVM) startedScript() string {
	source := vm.Source
	if source == "" {
		source = "auto"
	}
	return capture("guided_start_step_started", "{ step: '"+string(vm.Step)+"', source: '"+source+"' }")
}

func (o OutcomeVM) props(withElsewhere bool) string {
	props := "{ step: '" + string(o.Step) + "', elapsed_ms: " + strconv.FormatInt(o.ElapsedMs, 10)
	if withElsewhere {
		props += ", completed_elsewhere: " + strconv.FormatBool(o.Elsewhere)
	}
	return props + " }"
}

func rowLabel(i int, step guide.Step, done bool) string {
	state := "Not started"
	if done {
		state = "Done"
	}
	return "Step " + strconv.Itoa(i+1) + " of " + strconv.Itoa(len(guide.Steps)) + ", " + step.Title() + ", " + state
}

templ Card(vm CardVM) {
	if vm.Visible {
		<section
			id="guided-start-card"
			class="dash-panel guided-start-card p-5 md:p-6"
			aria-labelledby="guided-start-title"
			x-data="{ hidden: false }"
			x-show="!hidden"
			if vm.initScript() != "" {
				x-init={ vm.initScript() }
			}
		>
			<header class="flex items-start justify-between gap-4">
				<div>
					<p class="dash-panel-label">{ guide.ProgressLabel(vm.Progress.Count) }</p>
					<h2 id="guided-start-title" class="mt-2 text-xl font-semibold">{ guide.Headline }</h2>
				</div>
				@components.NativeButton(components.ButtonProps{
					Class: "dash-btn dash-btn-ghost guided-start-dismiss",
					Attributes: templ.Attributes{
						"aria-label": "Hide " + guide.Headline,
						"hx-post":    "/guided-start/dismiss",
						"hx-target":  "#guided-start-card",
						"hx-swap":    "outerHTML",
						"x-on:click": "hidden = true",
					},
				}) {
					<span aria-hidden="true">×</span>
				}
			</header>
			<ol class="guided-start-steps mt-4 space-y-2">
				for i, step := range guide.Steps {
					<li>
						<a
							href={ templ.SafeURL("/guided-start/start?step=" + string(step)) }
							class={ "guided-start-row", templ.KV("is-done", vm.Progress.Done[step]), templ.KV("is-next", vm.Progress.Next == step) }
							aria-label={ rowLabel(i, step, vm.Progress.Done[step]) }
							title={ step.Line() }
						>
							<span class="guided-start-marker" aria-hidden="true">
								if vm.Progress.Done[step] {
									✓
								} else {
									{ strconv.Itoa(i + 1) }
								}
							</span>
							<span class="guided-start-title">{ step.Title() }</span>
						</a>
					</li>
				}
			</ol>
			if vm.Progress.AllDone() {
				<p class="mt-4 text-sm font-semibold">{ guide.Completion }</p>
			}
			if vm.Message != "" {
				<p class="mt-3 text-sm text-muted-foreground" role="status">{ vm.Message }</p>
			}
		</section>
	}
}

templ WithStepLayer(content templ.Component, vm LayerVM) {
	@content
	@StepLayer(vm)
}

// StepLayer is not modal: the ring takes no pointer events and the page stays
// usable. With no matching target on the page there is no ring and no dim.
templ StepLayer(vm LayerVM) {
	<div
		id="guided-step-layer"
		class="guided-step-layer"
		x-data={ "guidedSpotlight('" + vm.Step.Target() + "')" }
		if vm.Announce {
			x-init={ vm.startedScript() }
		}
	>
		<div class="guided-step-ring" x-show="found" x-bind:style="ringStyle" aria-hidden="true"></div>
		<div class="guided-step-bubble" role="status" aria-live="polite" tabindex="-1" x-ref="bubble">
			<p class="text-sm font-semibold">{ vm.Step.Line() }</p>
			<div class="mt-3 flex items-center justify-end">
				@components.NativeButton(components.ButtonProps{
					Class: "dash-btn dash-btn-secondary",
					Attributes: templ.Attributes{
						"x-ref":   "skip",
						"hx-post": "/guided-start/skip",
						"hx-swap": "none",
					},
				}) {
					{ guide.SkipLabel }
				}
			</div>
			@Poller(0)
		</div>
	</div>
}

templ Poller(attempt int) {
	<div
		class="guided-step-poller"
		hx-get={ "/guided-start/poll?attempt=" + strconv.Itoa(attempt) }
		hx-trigger={ "load delay:" + strconv.Itoa(int(guide.PollDelay(attempt).Seconds())) + "s" }
		hx-swap="outerHTML"
		aria-hidden="true"
	></div>
}

// StepDone replaces the whole layer out of band: ring gone, a short confirmation left.
templ StepDone(o OutcomeVM) {
	<div
		id="guided-step-layer"
		class="guided-step-layer is-finished"
		hx-swap-oob
		x-data
		x-init={ capture("guided_start_step_completed", o.props(true)) }
	>
		<div class="guided-step-bubble" role="status" aria-live="polite">
			<p class="text-sm font-semibold">Done.</p>
			<a href="/dashboard" class="link-tint text-subhead font-semibold">Back to Get started</a>
		</div>
	</div>
}

// StepEnded removes the layer after recording why the step closed.
templ StepEnded(o OutcomeVM, event string) {
	<div id="guided-step-layer" hx-swap-oob x-data x-init={ capture(event, o.props(false)) + "; $el.remove()" }></div>
}

templ Dismissed() {
	<div hidden x-data x-init={ capture("guided_start_dismissed", "{}") }></div>
}
```

Two things to confirm while writing it:
- If `components.NativeButton` does not take children, check `internal/pages/components` for the variant that does; the dashboard uses it with children in `overview.templ`.
- If `templ generate` rejects the conditional attribute blocks, the local templ version predates them. Put the scripts on a nested `<div x-data x-init=…>` instead.

- [ ] **Step 4: Put the card on the dashboard and the layer on every app page**

1. In `internal/pages/dashboard/viewmodel.go`, add a field to `CommandCenterViewModel`:
   ```go
   	GuidedStart guidedstart.CardVM
   ```
   and import it as `"github.com/FinancePlanner/StockPlanWeb/internal/pages/guidedstart"`.
2. In `command_center.templ`, replace:
   ```templ
   		@commandCenterHeader(vm)
   		@OverviewAttentionPanel(vm.Overview)
   ```
   with:
   ```templ
   		@commandCenterHeader(vm)
   		@guidedstart.Card(vm.GuidedStart)
   		if !vm.GuidedStart.Visible {
   			@OverviewAttentionPanel(vm.Overview)
   		}
   ```
   and add the `guidedstart` import to the templ `import (...)` block.
3. In `pulse.templ`, change `if showOverviewSetup(vm.Overview) {` to `if showOverviewSetup(vm.Overview) && !vm.GuidedStart.Visible {`.
4. In `internal/handlers/app.go`:
   - In `Dashboard` and `DashboardPulse`, directly after `vm := LoadCommandCenterViewModel(...)`, add:
     ```go
     	vm.GuidedStart = h.guidedCardVM(r, h.loadGuidedProgress(r), "")
     ```
   - In `renderShell`, add this as the first line of the function:
     ```go
     	content = h.withGuidedStepLayer(r, content)
     ```

- [ ] **Step 5: Mark the three targets and add "Show me around"**

1. In `internal/pages/portfolio/holdings.templ`, in the `PrimaryButton` with `Class: "portfolio-add-btn"`, add `"data-guide": "holding-add"` to its `templ.Attributes`.
2. In `internal/pages/expenses/planner.templ`, in the `NativeButton` with `Class: "expenses-budget-salary command-metric"`, add `"data-guide": "budget-salary"` to its `templ.Attributes`.
3. In `internal/pages/goals/page.templ` `goalsHeaderActions`, add `"data-guide": "goal-create"` to the `NativeButton` attributes, next to `"x-on:click": "createOpen = true"`.
4. In `internal/pages/settings/settings.templ` `IndexPage`, add directly before `<form method="post" action="/logout" class="settings-logout-row">`:
   ```templ
   			<form method="post" action="/settings/show-me-around" class="settings-logout-row">
   				@components.CSRFField()
   				@components.SecondarySubmitButton(components.ButtonProps{Class: "px-5"}) { { i18n.T(ctx, "Show me around") } }
   			</form>
   ```

- [ ] **Step 6: Write the spotlight script and styles**

`internal/server/assets/guided-start.js`:

```js
// Guided start spotlight. It rings the control a step teaches and dims the
// rest with the ring's own shadow. The ring never takes pointer events, so
// the page stays usable; with no target on the page there is no ring and no
// dim, only the bubble.
export function registerGuidedStart(Alpine) {
  Alpine.data('guidedSpotlight', (target) => ({
    found: false,
    ringStyle: '',
    init() {
      this.locate = this.locate.bind(this)
      this.onKey = (event) => {
        if (event.key === 'Escape') this.$refs.skip?.click()
      }
      window.addEventListener('resize', this.locate)
      window.addEventListener('scroll', this.locate, { passive: true })
      document.body.addEventListener('htmx:after:settle', this.locate)
      document.addEventListener('keydown', this.onKey)
      const el = this.targetElement()
      if (el) {
        const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
        el.scrollIntoView({ block: 'center', behavior: reduce ? 'auto' : 'smooth' })
      }
      this.locate()
      this.$nextTick(() => this.$refs.bubble?.focus({ preventScroll: true }))
    },
    destroy() {
      window.removeEventListener('resize', this.locate)
      window.removeEventListener('scroll', this.locate)
      document.body.removeEventListener('htmx:after:settle', this.locate)
      document.removeEventListener('keydown', this.onKey)
    },
    targetElement() {
      return document.querySelector(`[data-guide="${target}"]`)
    },
    locate() {
      const rect = this.targetElement()?.getBoundingClientRect()
      if (!rect || rect.width === 0 || rect.height === 0) {
        this.found = false
        return
      }
      const pad = 8
      this.found = true
      this.ringStyle = `top:${rect.top - pad}px;left:${rect.left - pad}px;width:${rect.width + pad * 2}px;height:${rect.height + pad * 2}px`
    },
  }))
}
```

In `internal/server/assets/scripts.js`:
- Add `import { registerGuidedStart } from './guided-start.js'` with the other imports.
- Call `registerGuidedStart(Alpine)` directly before the boot block (`const bootRoot = document.documentElement`), next to the other `Alpine.data` registrations.

`internal/server/assets/css/guided-start.css`:

```css
.guided-start-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  border-radius: 0.75rem;
}
.guided-start-row:hover { background: color-mix(in oklab, currentColor 6%, transparent); }
.guided-start-row.is-done .guided-start-title { text-decoration: line-through; opacity: 0.6; }
.guided-start-marker {
  display: inline-grid;
  place-items: center;
  width: 1.5rem;
  height: 1.5rem;
  border-radius: 999px;
  border: 1px solid currentColor;
  font-size: 0.75rem;
}
.guided-start-row.is-next .guided-start-marker { background: var(--color-primary, currentColor); color: var(--color-primary-foreground, white); }

.guided-step-ring {
  position: fixed;
  z-index: 60;
  border-radius: 0.875rem;
  box-shadow: 0 0 0 100vmax rgb(0 0 0 / 0.55);
  pointer-events: none;
  transition: top 160ms ease, left 160ms ease, width 160ms ease, height 160ms ease;
}
.guided-step-bubble {
  position: fixed;
  z-index: 61;
  right: 1rem;
  bottom: 1rem;
  max-width: 22rem;
  padding: 1rem;
  border-radius: 1rem;
  background: var(--color-card, white);
  color: var(--color-card-foreground, inherit);
  box-shadow: 0 12px 32px rgb(0 0 0 / 0.2);
}
@media (prefers-reduced-motion: reduce) {
  .guided-step-ring { transition: none; }
}
```

In `internal/server/assets/styles.css`, add `@import './css/guided-start.css';` next to the existing `./css/` imports. Match whatever quote style the other imports use.

- [ ] **Step 7: Build and run the tests**

```bash
make assets
templ generate
go test ./internal/pages/... ./internal/handlers/ ./internal/guide/ ./internal/session/ -count=1
make check
```

Expected: PASS. `make check` also runs `check-controls` (no bare buttons) and lint.

- [ ] **Step 8: Commit**

```bash
git add internal/pages internal/handlers/app.go internal/server/assets
git commit -m "feat(guided-start): dashboard card, step layer with spotlight, targets, show me around"
```

---

### Task 8: iOS onboarding client and funnel resume

**Files:**
- Create:
  - `F/API/Onboarding/OnboardingEndpoints.swift`
  - `F/API/Onboarding/OnboardingHTTPClient.swift`
  - `F/API/Onboarding/Container+OnboardingFactories.swift`
  - `F/Features/Onboarding/OnboardingStateStore.swift`
  - `F/Features/Onboarding/OnboardingFunnelRouting.swift`
- Modify: `F/ContentView.swift`, `financeplan.xcodeproj/project.pbxproj` (shared pin)
- Test: `T/OnboardingHTTPClientTests.swift`, `T/OnboardingFunnelRoutingTests.swift`

**Interfaces:**
- Consumes: the shared DTOs (Task 1) and `GET`/`PATCH /v1/onboarding` (Task 2).
- Produces:
  - `protocol OnboardingClientProtocol: Sendable { func get() async throws -> OnboardingStateDTO; func patch(_: OnboardingPatchRequest) async throws -> OnboardingStateDTO }`
  - `@Observable @MainActor final class OnboardingStateStore`, with `state`, `refresh() -> OnboardingStateDTO?`, `apply(_:)`, `patch(_:) throws`, `recordFunnelStep(_:)`, `completeFunnel()` and `reset()`
  - `Container.onboardingClient`, `Container.onboardingStateStore`
  - `enum OnboardingFunnelRouting { static func route(server:localRequiresQuestionnaire:localHasImported:hasUserID:) -> (requiresQuestionnaire: Bool, requiresImport: Bool) }`

Point Xcode at the local shared worktree while developing:
1. Open `norviq-ios-guided/financeplan.xcodeproj`.
2. Drag `norviq-shared-guided` into the project navigator as a local package; Xcode prefers a local package over the remote one with the same identity.
3. Do not commit that local reference.

The pin bump to 5.13.0 is committed in Task 11.

- [ ] **Step 1: Write the failing tests**

`T/OnboardingFunnelRoutingTests.swift`:

```swift
import Foundation
import StockPlanShared
import Testing
@testable import financeplan

@Suite("Onboarding funnel routing")
struct OnboardingFunnelRoutingTests {
    private let finished = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("A finished funnel goes Home whatever the device remembers")
    func finished() {
        let route = OnboardingFunnelRouting.route(
            server: OnboardingStateDTO(funnelStep: "budget", funnelCompletedAt: finished),
            localRequiresQuestionnaire: true, localHasImported: false, hasUserID: true
        )
        #expect(route.requiresQuestionnaire == false)
        #expect(route.requiresImport == false)
    }

    @Test("A funnel left at the paywall on the web resumes at the paywall", arguments: ["questionnaire", "paywall"])
    func paywall(_ step: String) {
        let route = OnboardingFunnelRouting.route(
            server: OnboardingStateDTO(funnelStep: step),
            localRequiresQuestionnaire: false, localHasImported: true, hasUserID: true
        )
        #expect(route.requiresQuestionnaire)
        #expect(route.requiresImport)
    }

    @Test("A funnel left at import or budget resumes in the import flow", arguments: [nil, "welcome", "import", "budget"])
    func importFlow(_ step: String?) {
        let route = OnboardingFunnelRouting.route(
            server: OnboardingStateDTO(funnelStep: step),
            localRequiresQuestionnaire: false, localHasImported: true, hasUserID: true
        )
        #expect(route.requiresQuestionnaire == false)
        #expect(route.requiresImport)
    }

    @Test("An unreadable server falls back to the device flags")
    func offline() {
        let route = OnboardingFunnelRouting.route(
            server: nil, localRequiresQuestionnaire: false, localHasImported: true, hasUserID: true
        )
        #expect(route.requiresQuestionnaire == false)
        #expect(route.requiresImport == false)
    }
}
```

For `T/OnboardingHTTPClientTests.swift`, copy the `SessionMock` from `UserProfileHTTPClientTests.swift` into this file unchanged. Use the session protocol that `UserProfileHTTPClient`'s `session:` parameter accepts, which is `HTTPClientSession`.

```swift
import Foundation
import StockPlanShared
import XCTest
@testable import financeplan

@MainActor
final class OnboardingHTTPClientTests: XCTestCase {
  private final class SessionMock: HTTPClientSession, @unchecked Sendable {
    var handler: ((URLRequest) throws -> (Data, URLResponse))?
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      guard let handler else { fatalError("SessionMock.handler must be configured before use") }
      return try handler(request)
    }
  }

  private let body = Data(#"{"funnelStep":"import","funnelCompletedAt":null,"addHoldingCompleted":false,"setBudgetCompleted":false,"setGoalCompleted":false,"guidedStartDismissedAt":null}"#.utf8)

  func testPatchSendsOnlyTheSetFieldsWithBearer() async throws {
    let session = SessionMock()
    let baseURL = try XCTUnwrap(URL(string: "https://api.example.com"))
    session.handler = { request in
      XCTAssertEqual(request.httpMethod, "PATCH")
      XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/onboarding")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
      let sent = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any]
      XCTAssertEqual(sent?.keys.sorted(), ["funnelStep"])
      XCTAssertEqual(sent?["funnelStep"] as? String, "import")
      return (self.body, HTTPURLResponse(url: baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let client = OnboardingHTTPClient(baseURL: baseURL, session: session, authTokenProvider: { "token-123" })
    let state = try await client.patch(OnboardingPatchRequest(funnelStep: OnboardingFunnelStep.import.rawValue))
    XCTAssertEqual(state.funnelStep, "import")
  }
}
```

If `HTTPClientSession` is not the name `UserProfileHTTPClientTests` mocks (it uses `UserProfileURLSessionProtocol`), make the mock conform to whatever `BaseHTTPClient.init(session:)` takes. The compiler names it.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild -project financeplan.xcodeproj -scheme financeplan -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:financeplanTests/OnboardingFunnelRoutingTests -only-testing:financeplanTests/OnboardingHTTPClientTests test`
Expected: the build fails with "cannot find 'OnboardingFunnelRouting' in scope".

- [ ] **Step 3: Write the endpoints and client**

`F/API/Onboarding/OnboardingEndpoints.swift`:

```swift
import AnyAPI
import Foundation
import StockPlanShared

nonisolated struct GetOnboardingStateEndpoint: Endpoint {
  typealias Response = OnboardingStateDTO

  var method: HTTPMethod { .get }
  var path: String { "/v1/onboarding" }
  var decoder: JSONDecoder { .stockPlanShared }

  func asParameters() throws -> Parameters { [:] }
}

nonisolated struct PatchOnboardingStateEndpoint: Endpoint {
  typealias Response = OnboardingStateDTO

  let request: OnboardingPatchRequest

  var method: HTTPMethod { .patch }
  var path: String { "/v1/onboarding" }
  var decoder: JSONDecoder { .stockPlanShared }

  /// Only the fields that are set: the server rejects anything else.
  func asParameters() throws -> Parameters {
    var parameters: Parameters = [:]
    if let step = request.funnelStep { parameters["funnelStep"] = step }
    if let completed = request.funnelCompleted { parameters["funnelCompleted"] = completed }
    if let dismissed = request.guidedStartDismissed { parameters["guidedStartDismissed"] = dismissed }
    return parameters
  }
}
```

`F/API/Onboarding/OnboardingHTTPClient.swift`. Paste the whole `enum Error: HTTPClientError { … }` body from `F/API/UserProfile/UserProfileHTTPClient.swift` unchanged, including its `make…` factories:

```swift
import AnyAPI
import Foundation
import OSLog
import StockPlanShared

protocol OnboardingClientProtocol: Sendable {
  func get() async throws -> OnboardingStateDTO
  func patch(_ request: OnboardingPatchRequest) async throws -> OnboardingStateDTO
}

nonisolated struct OnboardingHTTPClient: OnboardingClientProtocol {
  // enum Error: HTTPClientError — copied verbatim from UserProfileHTTPClient.Error.

  private let client: BaseHTTPClient

  init(baseURL: URL, session: any HTTPClientSession = URLSession.shared, authTokenProvider: @escaping @Sendable () async -> String? = { nil }) {
    self.client = BaseHTTPClient(
      baseURL: baseURL,
      session: session,
      authTokenProvider: authTokenProvider,
      logger: Logger(subsystem: Bundle.main.bundleIdentifier ?? "financeplan", category: "OnboardingHTTPClient"),
      decoder: .stockPlanShared
    )
  }

  func get() async throws -> OnboardingStateDTO {
    try await client.call(GetOnboardingStateEndpoint(), errorType: Error.self)
  }

  func patch(_ request: OnboardingPatchRequest) async throws -> OnboardingStateDTO {
    try await client.call(PatchOnboardingStateEndpoint(request: request), errorType: Error.self)
  }
}
```

`F/API/Onboarding/Container+OnboardingFactories.swift`:

```swift
import Factory
import Foundation

extension Container {
  var onboardingClient: Factory<any OnboardingClientProtocol> {
    self { @MainActor [unowned self] in
      let env = self.appEnvironment()
      let auth = self.authSessionManager()
      return OnboardingHTTPClient(
        baseURL: env.current.apiBaseUrl,
        authTokenProvider: { try? await auth.validAccessToken() }
      )
    }
  }

  var onboardingStateStore: Factory<OnboardingStateStore> {
    self { @MainActor [unowned self] in OnboardingStateStore(client: self.onboardingClient()) }.singleton
  }
}
```

- [ ] **Step 4: Write the store and routing**

`F/Features/Onboarding/OnboardingStateStore.swift`:

```swift
import Foundation
import Observation
import OSLog
import StockPlanShared

/// The signed-in user's server-side onboarding row: funnel position for
/// ContentView, guided-start progress for Home. Contract:
/// norviq-shared/docs/guided-start.md.
@Observable @MainActor
final class OnboardingStateStore {
  private(set) var state: OnboardingStateDTO?

  @ObservationIgnored private let client: any OnboardingClientProtocol
  @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "financeplan", category: "OnboardingStateStore")

  init(client: any OnboardingClientProtocol) {
    self.client = client
  }

  /// Returns the fresh state, or nil when it could not be read. A failed read
  /// keeps whatever was already known.
  @discardableResult
  func refresh() async -> OnboardingStateDTO? {
    do {
      let fresh = try await client.get()
      state = fresh
      return fresh
    } catch {
      logger.warning("onboarding refresh failed: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }

  func apply(_ state: OnboardingStateDTO) {
    self.state = state
  }

  func patch(_ request: OnboardingPatchRequest) async throws {
    state = try await client.patch(request)
  }

  /// Best-effort, like the web: a failed write costs a resume, not the flow.
  func recordFunnelStep(_ step: OnboardingFunnelStep) async {
    try? await patch(OnboardingPatchRequest(funnelStep: step.rawValue))
  }

  func completeFunnel() async {
    try? await patch(OnboardingPatchRequest(funnelCompleted: true))
  }

  func reset() {
    state = nil
  }
}
```

`F/Features/Onboarding/OnboardingFunnelRouting.swift`:

```swift
import StockPlanShared

/// Where a signed-in user lands. iOS resumes at flow granularity: part of the
/// funnel runs before sign-in, where nothing can be stored on the server.
enum OnboardingFunnelRouting {
  static func route(
    server: OnboardingStateDTO?,
    localRequiresQuestionnaire: Bool,
    localHasImported: Bool,
    hasUserID: Bool
  ) -> (requiresQuestionnaire: Bool, requiresImport: Bool) {
    guard let server else {
      return (localRequiresQuestionnaire, !hasUserID || !localHasImported)
    }
    if server.funnelCompletedAt != nil {
      return (false, false)
    }
    let step = server.funnelStep.flatMap(OnboardingFunnelStep.init(rawValue:))
    let owesPaywall = localRequiresQuestionnaire || step == .questionnaire || step == .paywall
    return (owesPaywall, true)
  }
}
```

- [ ] **Step 5: Use it in `ContentView`**

1. In `applyAuthenticatedState()`, replace these lines:
   ```swift
         requiresOnboardingQuestionnaire = await sessionStore.requiresOnboardingQuestionnaire(for: userID)
         let hasImported = await sessionStore.hasCompletedInitialStockImport(for: userID)
         requiresInitialStockImport = userID.isEmpty || !hasImported
   ```
   with:
   ```swift
         let onboarding = Container.shared.onboardingStateStore()
         let server = await onboarding.refresh()
         let route = OnboardingFunnelRouting.route(
           server: server,
           localRequiresQuestionnaire: await sessionStore.requiresOnboardingQuestionnaire(for: userID),
           localHasImported: await sessionStore.hasCompletedInitialStockImport(for: userID),
           hasUserID: !userID.isEmpty
         )
         if server?.funnelCompletedAt != nil {
           await sessionStore.markOnboardingQuestionnaireCompleted(for: userID)
           await sessionStore.markInitialStockImportCompleted(for: userID)
         } else if server?.funnelStep != nil {
           PostHogSDK.shared.capture("onboarding_funnel_resumed", properties: ["step": server?.funnelStep ?? ""])
         }
         requiresOnboardingQuestionnaire = route.requiresQuestionnaire
         requiresInitialStockImport = route.requiresImport
   ```
   Add `import PostHog` to `ContentView.swift` if it is not already imported.
2. In both `onCompleted` closures (the authenticated `OnboardingQuestionnairePaywallScreen` and the unauthenticated `OnboardingQuestionnaireFlow`), add this line directly after `await sessionStore.markOnboardingQuestionnaireCompleted(for: userID)`:
   ```swift
                       await Container.shared.onboardingStateStore().recordFunnelStep(.import)
   ```
3. In the `OnboardingImportFlow(onFinished:)` closure, add this line directly after `await sessionStore.markInitialStockImportCompleted(for: userID)`:
   ```swift
                       await Container.shared.onboardingStateStore().completeFunnel()
   ```
4. In `handleSessionInvalidation()`, add:
   ```swift
       Container.shared.onboardingStateStore().reset()
   ```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `make ios-test`. For a faster run, use the `-only-testing` form from Step 2.
Expected: PASS, including the existing `OnboardingQuestionnaireViewModelTests` and `AuthSessionStoreTests`.

- [ ] **Step 7: Commit** (without the local package reference)

```bash
git add financeplan/API/Onboarding financeplan/Features/Onboarding/OnboardingStateStore.swift \
  financeplan/Features/Onboarding/OnboardingFunnelRouting.swift financeplan/ContentView.swift \
  financeplanTests/OnboardingFunnelRoutingTests.swift financeplanTests/OnboardingHTTPClientTests.swift
git commit -m "feat(onboarding): resume the iOS funnel from server-side progress"
```

---

### Task 9: iOS guided-start core (steps, anchors, coordinator, telemetry)

**Files:**
- Create, under `F/Features/Home/GuidedStart/`: `GuidedStartStep.swift`, `GuidedAnchors.swift`, `GuidedStartTelemetry.swift`, `GuidedStartCoordinator.swift`, `GuidedStartHost.swift`, and `GuidedSpotlightOverlay.swift` (geometry helpers only in this task; the view comes in Task 10)
- Test: `T/GuidedStartCoordinatorTests.swift`, `T/GuidedSpotlightGeometryTests.swift`

**Interfaces:**
- Consumes: `OnboardingClientProtocol`, `OnboardingStateStore` (Task 8).
- Produces:
  - Types:
    - `GuidedStartStep` (`.addHolding`, `.setBudget`, `.setGoal`)
    - `GuidedTarget` (`.holdingAdd`, `.budgetSalary`, `.goalCard`, `.goalCreate`)
    - `GuidedTab` (`.dashboard`, `.portfolio`, `.expenses`, `.goalPlanning`)
    - `GuidedStartProgress`, `GuidedStartCopy`
  - View modifier: `View.guidedTarget(_:in:)`.
  - `GuidedStartCoordinator`:
    - state: `phase`, `inlineMessage`, `requestedTab`, `progress`, `isCardVisible`, `activeStep`
    - actions: `noteCardShown()`, `refresh()`, `start(_:source:)`, `skip()`, `noteUserAction(_:)`, `dismissCard()`, `showMeAround()`
    - DEBUG only: `settle()`
  - Factory: `GuidedStartCoordinator.live(store:client:)`.
  - Geometry: `GuidedSpotlightGeometry.blockerRects(container:hole:)`, `GuidedSpotlightGeometry.showsScrim(hole:)`.

- [ ] **Step 1: Write the failing tests**

`T/GuidedStartCoordinatorTests.swift`:

```swift
import Foundation
import StockPlanShared
import Testing
@testable import financeplan

actor FakeOnboardingClient: OnboardingClientProtocol {
  var state: OnboardingStateDTO
  var failPatch = false

  init(_ state: OnboardingStateDTO) { self.state = state }

  func set(_ state: OnboardingStateDTO) { self.state = state }
  func setFailPatch(_ fail: Bool) { failPatch = fail }

  func get() async throws -> OnboardingStateDTO { state }

  func patch(_ request: OnboardingPatchRequest) async throws -> OnboardingStateDTO {
    if failPatch { throw URLError(.notConnectedToInternet) }
    if let dismissed = request.guidedStartDismissed {
      state = OnboardingStateDTO(
        funnelStep: state.funnelStep, funnelCompletedAt: state.funnelCompletedAt,
        addHoldingCompleted: state.addHoldingCompleted, setBudgetCompleted: state.setBudgetCompleted,
        setGoalCompleted: state.setGoalCompleted, guidedStartDismissedAt: dismissed ? Date() : nil
      )
    }
    return state
  }
}

@MainActor
final class RecordingAnalytics: GuidedStartAnalytics {
  var events: [(name: String, properties: [String: Any]?)] = []
  func capture(_ event: String, properties: [String: Any]?) { events.append((event, properties)) }
  var names: [String] { events.map(\.name) }
}

@MainActor
final class Clock {
  var now = Date(timeIntervalSince1970: 1_800_000_000)
  var slept: [Duration] = []
}

@MainActor
private func state(holding: Bool = false, budget: Bool = false, goal: Bool = false, funnelDone: Bool = true, dismissed: Bool = false) -> OnboardingStateDTO {
  OnboardingStateDTO(
    funnelStep: funnelDone ? "done" : "import",
    funnelCompletedAt: funnelDone ? Date(timeIntervalSince1970: 1_700_000_000) : nil,
    addHoldingCompleted: holding, setBudgetCompleted: budget, setGoalCompleted: goal,
    guidedStartDismissedAt: dismissed ? Date(timeIntervalSince1970: 1_700_000_000) : nil
  )
}

@MainActor
private func makeCoordinator(_ initial: OnboardingStateDTO) -> (GuidedStartCoordinator, FakeOnboardingClient, OnboardingStateStore, RecordingAnalytics, Clock) {
  let client = FakeOnboardingClient(initial)
  let store = OnboardingStateStore(client: client)
  store.apply(initial)
  let analytics = RecordingAnalytics()
  let clock = Clock()
  let coordinator = GuidedStartCoordinator(
    client: client,
    telemetry: GuidedStartTelemetry(analytics: analytics),
    now: { clock.now },
    sleep: { duration in
      clock.slept.append(duration)
      clock.now += Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
      await Task.yield()
    },
    snapshot: { store.state },
    applySnapshot: { store.apply($0) }
  )
  return (coordinator, client, store, analytics, clock)
}

@Suite("Guided start coordinator")
@MainActor
struct GuidedStartCoordinatorTests {
  @Test("Card visibility follows the contract")
  func visibility() {
    #expect(makeCoordinator(state()).0.isCardVisible)
    #expect(makeCoordinator(state(funnelDone: false)).0.isCardVisible == false)
    #expect(makeCoordinator(state(dismissed: true)).0.isCardVisible == false)
    #expect(makeCoordinator(state(holding: true, budget: true, goal: true)).0.isCardVisible == false)
  }

  @Test("Starting a done step skips ahead and asks for that step's tab")
  func skipAhead() async {
    let (coordinator, _, _, analytics, _) = makeCoordinator(state(holding: true))
    await coordinator.start(.addHolding)
    #expect(coordinator.activeStep == .setBudget)
    #expect(coordinator.requestedTab == .expenses)
    #expect(analytics.names == ["guided_start_step_started"])
    #expect(analytics.events[0].properties?["step"] as? String == "set_budget")
    coordinator.skip()
  }

  @Test("Polls on 1s, 2s, 4s, 8s, then 10s, and times out after 5 minutes")
  func pollScheduleAndTimeout() async {
    let (coordinator, _, _, analytics, clock) = makeCoordinator(state())
    await coordinator.start(.addHolding)
    await coordinator.settle()
    #expect(Array(clock.slept.prefix(6)) == [.seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(10), .seconds(10)])
    #expect(analytics.names.last == "guided_start_step_timed_out")
    #expect(coordinator.phase == .idle)
  }

  @Test("A local action polls at once and completes without completed_elsewhere")
  func localCompletion() async {
    let (coordinator, client, _, analytics, _) = makeCoordinator(state())
    await coordinator.start(.addHolding)
    await client.set(state(holding: true))
    coordinator.noteUserAction(.addHolding)
    await coordinator.settle()
    let completed = analytics.events.first { $0.name == "guided_start_step_completed" }
    #expect(completed?.properties?["completed_elsewhere"] as? Bool == false)
    #expect(coordinator.phase == .idle)
  }

  @Test("A latch flipping without a local action is completed elsewhere")
  func elsewhereCompletion() async {
    let (coordinator, client, _, analytics, _) = makeCoordinator(state())
    await coordinator.start(.setGoal)
    await client.set(state(goal: true))
    await coordinator.settle()
    let completed = analytics.events.first { $0.name == "guided_start_step_completed" }
    #expect(completed?.properties?["completed_elsewhere"] as? Bool == true)
  }

  @Test("Finishing the last step shows the completed card, then fires completed once")
  func lastStep() async {
    let (coordinator, client, _, analytics, _) = makeCoordinator(state(holding: true, budget: true))
    await coordinator.start(.setGoal)
    await client.set(state(holding: true, budget: true, goal: true))
    await coordinator.settle()
    #expect(coordinator.phase == .finished)
    #expect(coordinator.isCardVisible)
    #expect(analytics.names.filter { $0 == "guided_start_completed" }.count == 1)
  }

  @Test("A failed dismiss restores the card and says so")
  func dismissFailure() async {
    let (coordinator, client, _, _, _) = makeCoordinator(state())
    await client.setFailPatch(true)
    await coordinator.dismissCard()
    #expect(coordinator.isCardVisible)
    #expect(coordinator.inlineMessage == GuidedStartCopy.dismissFailed)
  }

  @Test("A dismissal from another device waits for the open step")
  func dismissalElsewhereWaitsForOpenStep() async {
    let (coordinator, _, store, _, _) = makeCoordinator(state())
    await coordinator.start(.addHolding)
    store.apply(state(dismissed: true))
    #expect(coordinator.isCardVisible, "an engaged step keeps the card")
    coordinator.skip()
    #expect(coordinator.isCardVisible == false)
  }

  @Test("Show me around on a finished wizard shows the completed card this session")
  func showMeAround() async {
    let (coordinator, _, _, analytics, _) = makeCoordinator(state(holding: true, budget: true, goal: true, dismissed: true))
    await coordinator.showMeAround()
    #expect(coordinator.isCardVisible)
    #expect(analytics.names == ["guided_start_reopened"])
  }
}
```

`T/GuidedSpotlightGeometryTests.swift`:

```swift
import CoreGraphics
import Testing
@testable import financeplan

@Suite("Guided spotlight geometry")
struct GuidedSpotlightGeometryTests {
  private let container = CGSize(width: 400, height: 800)

  @Test("No hole means no scrim and nothing blocking touches")
  func noHoleMeansNoScrim() {
    #expect(GuidedSpotlightGeometry.showsScrim(hole: nil) == false)
    #expect(GuidedSpotlightGeometry.blockerRects(container: container, hole: nil).isEmpty)
  }

  @Test("A hole leaves exactly its own rect touchable")
  func blockersSurroundHole() {
    let hole = CGRect(x: 100, y: 300, width: 200, height: 60)
    let blockers = GuidedSpotlightGeometry.blockerRects(container: container, hole: hole)
    #expect(blockers.count == 4)
    #expect(blockers.allSatisfy { !$0.intersects(hole.insetBy(dx: 1, dy: 1)) })
    #expect(GuidedSpotlightGeometry.showsScrim(hole: hole))
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild … -only-testing:financeplanTests/GuidedStartCoordinatorTests -only-testing:financeplanTests/GuidedSpotlightGeometryTests test`, using the destination from Task 8.
Expected: the build fails with "cannot find 'GuidedStartCoordinator' in scope".

- [ ] **Step 3: Write `GuidedStartStep.swift`**

```swift
import Foundation
import StockPlanShared

/// A place in the UI the spotlight can frame. A target is not a step: the
/// goal step passes through two.
enum GuidedTarget: String, Sendable, CaseIterable {
  case holdingAdd = "holding-add"
  case budgetSalary = "budget-salary"
  case goalCard = "goal-card"
  case goalCreate = "goal-create"
}

/// Where an anchor lives. `goalPlanning` is the full-screen cover, which has
/// its own overlay because anchors do not cross a presentation.
enum GuidedTab: String, Sendable {
  case dashboard
  case portfolio
  case expenses
  case goalPlanning
}

enum GuidedStartStep: String, CaseIterable, Identifiable, Sendable {
  case addHolding = "add_holding"
  case setBudget = "set_budget"
  case setGoal = "set_goal"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .addHolding: String(localized: "Add a holding")
    case .setBudget: String(localized: "Set your budget")
    case .setGoal: String(localized: "Set a goal")
    }
  }

  var line: String {
    switch self {
    case .addHolding: String(localized: "Add one stock or ETF you own.")
    case .setBudget: String(localized: "Enter your monthly take-home pay.")
    case .setGoal: String(localized: "Pick one thing you're saving for.")
    }
  }

  /// First the place the step starts, then anything it leads into.
  var targets: [GuidedTarget] {
    switch self {
    case .addHolding: [.holdingAdd]
    case .setBudget: [.budgetSalary]
    case .setGoal: [.goalCard, .goalCreate]
    }
  }

  /// The tab the step starts on.
  var tab: GuidedTab {
    switch self {
    case .addHolding: .portfolio
    case .setBudget: .expenses
    case .setGoal: .dashboard
    }
  }

  func isComplete(in state: OnboardingStateDTO) -> Bool {
    switch self {
    case .addHolding: state.addHoldingCompleted
    case .setBudget: state.setBudgetCompleted
    case .setGoal: state.setGoalCompleted
    }
  }
}

struct GuidedStartProgress: Equatable, Sendable {
  let completed: Set<GuidedStartStep>
  let next: GuidedStartStep?

  var isAllDone: Bool { next == nil }
  var completedCount: Int { completed.count }

  init(_ state: OnboardingStateDTO?) {
    guard let state else {
      completed = []
      next = GuidedStartStep.allCases.first
      return
    }
    completed = Set(GuidedStartStep.allCases.filter { $0.isComplete(in: state) })
    next = GuidedStartStep.allCases.first { !$0.isComplete(in: state) }
  }
}

enum GuidedStartCopy {
  static let headline = String(localized: "Get started with Norviq")
  static let skip = String(localized: "Skip")
  static let completion = String(localized: "You're set up. Everything else builds on these three.")
  static let dismissFailed = String(localized: "Couldn't hide that just now — try again in a moment.")
  static let reopenFailed = String(localized: "Here for now — I couldn't save that, so this may hide again next time.")

  static func progress(completed: Int) -> String {
    "\(completed) of \(GuidedStartStep.allCases.count)"
  }
}
```

- [ ] **Step 4: Write `GuidedAnchors.swift`** (ported from Lumina, with multi-target lookup)

```swift
import SwiftUI

// Anchors, not named coordinate spaces: across a tab or sheet boundary a named
// space silently resolves to window coordinates. A tab the user has left keeps
// publishing stale anchors, so every key carries the tab its view lives on, and
// the overlay only reads the active tab's keys. Anchors raised inside a
// presented sheet or cover never reach an overlay outside it.

struct GuidedAnchorID: Hashable, Sendable {
  let tab: GuidedTab
  let target: GuidedTarget
}

enum GuidedAnchorKey: PreferenceKey {
  static let defaultValue: [GuidedAnchorID: Anchor<CGRect>] = [:]

  static func reduce(value: inout [GuidedAnchorID: Anchor<CGRect>], nextValue: () -> [GuidedAnchorID: Anchor<CGRect>]) {
    value.merge(nextValue()) { _, new in new }
  }
}

extension View {
  /// Publishes this view's bounds as `target` on `tab` — the tab it lives on,
  /// a constant at every call site. Mark the smallest view that is the control.
  func guidedTarget(_ target: GuidedTarget, in tab: GuidedTab) -> some View {
    anchorPreference(key: GuidedAnchorKey.self, value: .bounds) { anchor in
      [GuidedAnchorID(tab: tab, target: target): anchor]
    }
  }
}

extension Dictionary where Key == GuidedAnchorID, Value == Anchor<CGRect> {
  /// The first of `targets` present on `tab`, or nil.
  func anchor(for targets: [GuidedTarget], on tab: GuidedTab?) -> Anchor<CGRect>? {
    guard let tab else { return nil }
    return targets.lazy.compactMap { self[GuidedAnchorID(tab: tab, target: $0)] }.first
  }
}
```

- [ ] **Step 5: Write `GuidedStartTelemetry.swift`**

```swift
import Foundation
import PostHog

enum GuidedStartEvent {
  static let cardShown = "guided_start_card_shown"
  static let stepStarted = "guided_start_step_started"
  static let stepCompleted = "guided_start_step_completed"
  static let stepSkipped = "guided_start_step_skipped"
  static let stepTimedOut = "guided_start_step_timed_out"
  static let dismissed = "guided_start_dismissed"
  static let reopened = "guided_start_reopened"
  static let completed = "guided_start_completed"
}

enum GuidedStartSource: String, Sendable {
  case auto
  case settings
}

@MainActor
protocol GuidedStartAnalytics: AnyObject {
  func capture(_ event: String, properties: [String: Any]?)
}

@MainActor
final class PostHogGuidedStartAnalytics: GuidedStartAnalytics {
  func capture(_ event: String, properties: [String: Any]?) {
    PostHogSDK.shared.capture(event, properties: properties)
  }
}

@MainActor
struct GuidedStartTelemetry {
  private let analytics: any GuidedStartAnalytics

  init(analytics: any GuidedStartAnalytics = PostHogGuidedStartAnalytics()) {
    self.analytics = analytics
  }

  func cardShown() { analytics.capture(GuidedStartEvent.cardShown, properties: nil) }
  func dismissed() { analytics.capture(GuidedStartEvent.dismissed, properties: nil) }
  func reopened() { analytics.capture(GuidedStartEvent.reopened, properties: nil) }
  func completed() { analytics.capture(GuidedStartEvent.completed, properties: nil) }

  func stepStarted(_ step: GuidedStartStep, source: GuidedStartSource) {
    analytics.capture(GuidedStartEvent.stepStarted, properties: ["step": step.rawValue, "source": source.rawValue])
  }

  func stepCompleted(_ step: GuidedStartStep, elapsedMs: Int, completedElsewhere: Bool) {
    analytics.capture(GuidedStartEvent.stepCompleted, properties: [
      "step": step.rawValue, "elapsed_ms": elapsedMs, "completed_elsewhere": completedElsewhere,
    ])
  }

  func stepSkipped(_ step: GuidedStartStep, elapsedMs: Int) {
    analytics.capture(GuidedStartEvent.stepSkipped, properties: ["step": step.rawValue, "elapsed_ms": elapsedMs])
  }

  func stepTimedOut(_ step: GuidedStartStep, elapsedMs: Int) {
    analytics.capture(GuidedStartEvent.stepTimedOut, properties: ["step": step.rawValue, "elapsed_ms": elapsedMs])
  }
}
```

- [ ] **Step 6: Write `GuidedStartCoordinator.swift`** (Lumina's, minus the mascot, confetti and pending-capture guard)

```swift
import Foundation
import Observation
import StockPlanShared

/// Drives the "Get started with Norviq" card and its steps. Completion is the
/// server's word: a step finishes when its latch flips on a poll, never when
/// the client thinks it saved. Contract: norviq-shared/docs/guided-start.md.
@MainActor
@Observable
final class GuidedStartCoordinator {
  enum Phase: Equatable {
    case idle
    case active(GuidedStartStep, startedAt: Date)
    case celebrating(GuidedStartStep)
    case finished

    /// The card stays while any of these hold, even if a dismissal arrives
    /// from another device mid-step.
    var isEngaged: Bool {
      if case .idle = self { return false }
      return true
    }
  }

  /// 1s, 2s, 4s, 8s, then every 10s, giving up after 5 minutes.
  private static let pollBackoff: [Duration] = [.seconds(1), .seconds(2), .seconds(4), .seconds(8)]
  private static let pollSteadyState: Duration = .seconds(10)
  static let stepTimeout: TimeInterval = 300
  private static let celebrationDwell: Duration = .milliseconds(1_600)

  private(set) var phase: Phase = .idle
  private(set) var inlineMessage: String?
  private(set) var requestedTab: GuidedTab?
  private var dismissOverride: Bool?
  private var sessionShowsCompletedCard = false

  @ObservationIgnored private let client: any OnboardingClientProtocol
  @ObservationIgnored private let telemetry: GuidedStartTelemetry
  @ObservationIgnored private let now: @MainActor () -> Date
  @ObservationIgnored private let sleep: @MainActor (Duration) async throws -> Void
  @ObservationIgnored private let snapshot: @MainActor () -> OnboardingStateDTO?
  @ObservationIgnored private let applySnapshot: @MainActor (OnboardingStateDTO) -> Void

  @ObservationIgnored private var pendingSource: GuidedStartSource?
  @ObservationIgnored private var didFireCardShown = false
  @ObservationIgnored private var locallyActed: Set<GuidedStartStep> = []
  @ObservationIgnored private var work: Task<Void, Never>?
  @ObservationIgnored private var workGeneration = 0
  @ObservationIgnored private var runID = 0
  @ObservationIgnored private var pollIndex = 0

  init(
    client: any OnboardingClientProtocol,
    telemetry: GuidedStartTelemetry,
    now: @MainActor @escaping () -> Date = { Date() },
    sleep: @MainActor @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    snapshot: @MainActor @escaping () -> OnboardingStateDTO?,
    applySnapshot: @MainActor @escaping (OnboardingStateDTO) -> Void
  ) {
    self.client = client
    self.telemetry = telemetry
    self.now = now
    self.sleep = sleep
    self.snapshot = snapshot
    self.applySnapshot = applySnapshot
  }

  // MARK: - Derived state

  var progress: GuidedStartProgress { GuidedStartProgress(snapshot()) }

  var activeStep: GuidedStartStep? {
    if case .active(let step, _) = phase { return step }
    return nil
  }

  var isDismissed: Bool { dismissOverride ?? (snapshot()?.guidedStartDismissedAt != nil) }

  var isCardVisible: Bool {
    guard let state = snapshot(), state.funnelCompletedAt != nil else { return false }
    if phase.isEngaged { return true }
    if isDismissed { return false }
    if progress.isAllDone { return sessionShowsCompletedCard }
    return true
  }

  // MARK: - Card lifecycle

  func noteCardShown() {
    guard isCardVisible, !didFireCardShown else { return }
    didFireCardShown = true
    telemetry.cardShown()
  }

  func refresh() async {
    guard let state = try? await client.get() else { return }
    applySnapshot(state)
  }

  // MARK: - Steps

  func start(_ step: GuidedStartStep, source: GuidedStartSource = .auto) async {
    inlineMessage = nil
    cancelWork()
    await refresh()

    guard let target = resolveStart(step) else {
      finishWizard()
      return
    }

    let startedAt = now()
    locallyActed.remove(target)
    pollIndex = 0
    runID += 1
    let run = runID

    phase = .active(target, startedAt: startedAt)
    requestedTab = target.tab
    telemetry.stepStarted(target, source: pendingSource ?? source)
    pendingSource = nil

    startPolling(target, startedAt: startedAt, run: run, delayIndex: 0, pollImmediately: false)
  }

  /// Skip closes this step; the card stays.
  func skip() {
    guard case .active(let step, let startedAt) = phase else { return }
    cancelWork()
    runID += 1
    telemetry.stepSkipped(step, elapsedMs: elapsedMs(since: startedAt))
    closeStep()
  }

  /// The user did the step's action here. Poll now instead of on the next tick.
  func noteUserAction(_ step: GuidedStartStep) {
    locallyActed.insert(step)
    guard case .active(let current, let startedAt) = phase, current == step else { return }
    let resumeIndex = pollIndex
    cancelWork()
    runID += 1
    startPolling(step, startedAt: startedAt, run: runID, delayIndex: resumeIndex, pollImmediately: true)
  }

  // MARK: - Dismissal

  func dismissCard() async {
    dismissOverride = true
    inlineMessage = nil
    telemetry.dismissed()
    do {
      applySnapshot(try await client.patch(OnboardingPatchRequest(guidedStartDismissed: true)))
    } catch {
      dismissOverride = nil
      inlineMessage = GuidedStartCopy.dismissFailed
    }
  }

  func showMeAround() async {
    dismissOverride = false
    inlineMessage = nil
    pendingSource = .settings
    if progress.isAllDone { sessionShowsCompletedCard = true }
    telemetry.reopened()
    do {
      applySnapshot(try await client.patch(OnboardingPatchRequest(guidedStartDismissed: false)))
    } catch {
      inlineMessage = GuidedStartCopy.reopenFailed
    }
  }

  // MARK: - Polling

  private enum Tick { case keepGoing, stop }

  private func startPolling(_ step: GuidedStartStep, startedAt: Date, run: Int, delayIndex: Int, pollImmediately: Bool) {
    let sleep = self.sleep
    let backoff = Self.pollBackoff
    let steady = Self.pollSteadyState

    workGeneration += 1
    work = Task { [weak self] in
      var index = delayIndex
      var immediate = pollImmediately
      while true {
        if Task.isCancelled { return }
        if immediate {
          immediate = false
        } else {
          let delay = index < backoff.count ? backoff[index] : steady
          index += 1
          self?.pollIndex = index
          do { try await sleep(delay) } catch { return }
        }
        guard let tick = await self?.pollTick(step, startedAt: startedAt, run: run) else { return }
        if tick == .stop { return }
      }
    }
  }

  private func pollTick(_ step: GuidedStartStep, startedAt: Date, run: Int) async -> Tick {
    guard isRunning(step, run: run) else { return .stop }
    if let state = try? await client.get() {
      guard isRunning(step, run: run) else { return .stop }
      applySnapshot(state)
      if step.isComplete(in: state) {
        await complete(step, startedAt: startedAt)
        return .stop
      }
    }
    guard isRunning(step, run: run) else { return .stop }
    if now().timeIntervalSince(startedAt) >= Self.stepTimeout {
      telemetry.stepTimedOut(step, elapsedMs: elapsedMs(since: startedAt))
      closeStep()
      return .stop
    }
    return .keepGoing
  }

  private func complete(_ step: GuidedStartStep, startedAt: Date) async {
    telemetry.stepCompleted(step, elapsedMs: elapsedMs(since: startedAt), completedElsewhere: !locallyActed.contains(step))
    locallyActed.remove(step)
    requestedTab = nil
    phase = .celebrating(step)
    let allDone = progress.isAllDone
    try? await sleep(Self.celebrationDwell)
    guard case .celebrating(let current) = phase, current == step else { return }
    if allDone {
      phase = .finished
      telemetry.completed()
    } else {
      phase = .idle
    }
  }

  // MARK: - Helpers

  private func resolveStart(_ step: GuidedStartStep) -> GuidedStartStep? {
    guard let state = snapshot() else { return step }
    if !step.isComplete(in: state) { return step }
    return progress.next
  }

  private func finishWizard() {
    guard phase != .finished else { return }
    requestedTab = nil
    phase = .finished
    telemetry.completed()
  }

  private func closeStep() {
    requestedTab = nil
    inlineMessage = nil
    phase = .idle
  }

  private func isRunning(_ step: GuidedStartStep, run: Int) -> Bool {
    guard !Task.isCancelled, run == runID else { return false }
    guard case .active(let current, _) = phase, current == step else { return false }
    return true
  }

  private func elapsedMs(since startedAt: Date) -> Int {
    Int((now().timeIntervalSince(startedAt) * 1_000).rounded())
  }

  private func cancelWork() {
    work?.cancel()
    work = nil
  }

  #if DEBUG
  /// Waits for polling to finish, including work that replaced itself.
  func settle() async {
    for _ in 0..<64 {
      guard let task = work else { return }
      let generation = workGeneration
      await task.value
      if workGeneration == generation {
        work = nil
        return
      }
    }
  }
  #endif
}
```

- [ ] **Step 7: Write `GuidedStartHost.swift`**

```swift
import SwiftUI

extension GuidedStartCoordinator {
  /// Production wiring. One per signed-in shell, created in HomeScreen.
  static func live(
    store: OnboardingStateStore = Container.shared.onboardingStateStore(),
    client: any OnboardingClientProtocol = Container.shared.onboardingClient()
  ) -> GuidedStartCoordinator {
    GuidedStartCoordinator(
      client: client,
      telemetry: GuidedStartTelemetry(),
      snapshot: { store.state },
      applySnapshot: { store.apply($0) }
    )
  }
}

private struct ReopenGuidedStartKey: EnvironmentKey {
  static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
  /// Settings › "Show me around". Nil outside the signed-in shell.
  var norviqReopenGuidedStart: (() -> Void)? {
    get { self[ReopenGuidedStartKey.self] }
    set { self[ReopenGuidedStartKey.self] = newValue }
  }
}
```

Add `import Factory` if `Container` is not visible without it.

- [ ] **Step 8: Write the geometry half of `GuidedSpotlightOverlay.swift`**

The view itself comes in Task 10.

```swift
import SwiftUI

enum GuidedSpotlightGeometry {
  /// No anchor, no dim: a scrim with nothing to tap is a dead end.
  static func showsScrim(hole: CGRect?) -> Bool { hole != nil }

  /// Four rects around the hole that swallow touches, leaving only the hole
  /// live. Empty without a hole, so a missing anchor blocks nothing.
  static func blockerRects(container: CGSize, hole: CGRect?) -> [CGRect] {
    let full = CGRect(origin: .zero, size: container)
    guard let hole = hole?.intersection(full), !hole.isNull, !hole.isEmpty else { return [] }
    return [
      CGRect(x: 0, y: 0, width: container.width, height: hole.minY),
      CGRect(x: 0, y: hole.maxY, width: container.width, height: container.height - hole.maxY),
      CGRect(x: 0, y: hole.minY, width: hole.minX, height: hole.height),
      CGRect(x: hole.maxX, y: hole.minY, width: container.width - hole.maxX, height: hole.height),
    ].filter { $0.width > 0.5 && $0.height > 0.5 }
  }
}
```

- [ ] **Step 9: Run the tests to verify they pass**

Run the `-only-testing` command from Step 2.
Expected: PASS for all 11 tests.

- [ ] **Step 10: Commit**

```bash
git add financeplan/Features/Home/GuidedStart financeplanTests/GuidedStartCoordinatorTests.swift financeplanTests/GuidedSpotlightGeometryTests.swift
git commit -m "feat(guided-start): coordinator, steps, anchors and telemetry for iOS"
```

---

### Task 10: iOS guided-start UI and wiring

**Files:**
- Create: `F/Features/Home/GuidedStart/GuidedStartCard.swift`. Extend `GuidedSpotlightOverlay.swift` with the view and the `guidedSpotlight` modifier.
- Modify:
  - `F/Features/Home/HomeScreen.swift`, `F/Features/Home/DashboardRoot.swift`
  - `F/Features/Portfolio/PortfolioListContent.swift`, `F/Features/Portfolio/PortfolioScreen.swift`
  - `F/Features/Expenses/ExpensesPlannerScreen.swift`
  - `F/Features/GoalPlanning/GoalPlanningScreen.swift`
  - `F/Features/UserProfile/UserProfileView.swift`

**Interfaces:**
- Consumes: everything from Task 9.
- Produces:
  - `GuidedStartCard(progress:message:onSelect:onDismiss:)`
  - `View.guidedSpotlight(step:activeTab:onSkip:)`

- [ ] **Step 1: Write the overlay view** (append to `GuidedSpotlightOverlay.swift`)

```swift
struct GuidedSpotlightOverlay: View {
  let step: GuidedStartStep?
  let activeTab: GuidedTab?
  let anchors: [GuidedAnchorID: Anchor<CGRect>]
  let onSkip: () -> Void

  @AccessibilityFocusState private var bubbleFocused: Bool

  private static let holeInset: CGFloat = 8
  private static let holeRadius: CGFloat = 14
  private static let dimOpacity: Double = 0.55
  private static let bubbleMaxWidth: CGFloat = 340

  var body: some View {
    if let step {
      GeometryReader { proxy in
        let hole = resolvedHole(step: step, proxy: proxy)
        ZStack(alignment: .bottom) {
          if GuidedSpotlightGeometry.showsScrim(hole: hole), let hole {
            scrim(container: proxy.size, hole: hole)
          }
          ForEach(Array(GuidedSpotlightGeometry.blockerRects(container: proxy.size, hole: hole).enumerated()), id: \.offset) { _, rect in
            Color.clear
              .frame(width: rect.width, height: rect.height)
              .contentShape(.rect)
              .onTapGesture {}
              .position(x: rect.midX, y: rect.midY)
              .accessibilityHidden(true)
          }
          bubble(step: step)
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
      }
      .ignoresSafeArea()
      .appAnimation(AppMotion.state, value: step)
      .onAppear { bubbleFocused = true }
    }
  }

  private func resolvedHole(step: GuidedStartStep, proxy: GeometryProxy) -> CGRect? {
    guard let anchor = anchors.anchor(for: step.targets, on: activeTab) else { return nil }
    let rect = proxy[anchor].insetBy(dx: -Self.holeInset, dy: -Self.holeInset)
    guard rect.width > 0, rect.height > 0, rect.intersects(CGRect(origin: .zero, size: proxy.size)) else { return nil }
    return rect
  }

  private func scrim(container: CGSize, hole: CGRect) -> some View {
    Path { path in
      path.addRect(CGRect(origin: .zero, size: container))
      path.addRoundedRect(in: hole, cornerSize: CGSize(width: Self.holeRadius, height: Self.holeRadius), style: .continuous)
    }
    .fill(Color.black.opacity(Self.dimOpacity), style: FillStyle(eoFill: true))
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func bubble(step: GuidedStartStep) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(step.line)
        .typography(.small, weight: .semibold)
        .accessibilityFocused($bubbleFocused)
      HStack {
        Spacer()
        Button(GuidedStartCopy.skip, action: onSkip)
          .buttonStyle(.bordered)
          .controlSize(.small)
      }
    }
    .padding(16)
    .frame(maxWidth: Self.bubbleMaxWidth, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .accessibilityElement(children: .contain)
    .accessibilityAction(.escape, onSkip)
  }
}

extension View {
  /// Attach once per presentation: the tab shell, and each cover a step passes through.
  func guidedSpotlight(step: GuidedStartStep?, activeTab: GuidedTab?, onSkip: @escaping () -> Void) -> some View {
    overlayPreferenceValue(GuidedAnchorKey.self) { anchors in
      GuidedSpotlightOverlay(step: step, activeTab: activeTab, anchors: anchors, onSkip: onSkip)
    }
  }
}
```

- [ ] **Step 2: Write `GuidedStartCard.swift`**

```swift
import SwiftUI

struct GuidedStartCard: View {
  let progress: GuidedStartProgress
  var message: String?
  let onSelect: (GuidedStartStep) -> Void
  let onDismiss: () -> Void

  var body: some View {
    GlassCard(cornerRadius: 18) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(GuidedStartCopy.progress(completed: progress.completedCount))
              .typography(.nano)
              .foregroundStyle(.secondary)
            Text(GuidedStartCopy.headline)
              .typography(.small, weight: .semibold)
          }
          Spacer()
          Button("Hide \(GuidedStartCopy.headline)", systemImage: "xmark", action: onDismiss)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        ForEach(Array(GuidedStartStep.allCases.enumerated()), id: \.element) { index, step in
          row(index: index, step: step)
        }
        if progress.isAllDone {
          Text(GuidedStartCopy.completion)
            .typography(.small, weight: .semibold)
        }
        if let message {
          Text(message)
            .typography(.nano)
            .foregroundStyle(.secondary)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(GuidedStartCopy.headline), \(GuidedStartCopy.progress(completed: progress.completedCount))")
  }

  private func row(index: Int, step: GuidedStartStep) -> some View {
    let done = progress.completed.contains(step)
    return Button {
      onSelect(step)
    } label: {
      HStack(spacing: 12) {
        ZStack {
          Circle().strokeBorder(.secondary, lineWidth: 1).frame(width: 24, height: 24)
          if done {
            Image(systemName: "checkmark").font(.caption.bold())
          } else {
            Text("\(index + 1)").typography(.nano)
          }
        }
        Text(step.title)
          .typography(.small)
          .strikethrough(done)
          .foregroundStyle(done ? .secondary : .primary)
        Spacer()
        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Step \(index + 1) of \(GuidedStartStep.allCases.count), \(step.title)")
    .accessibilityValue(done ? "Done" : "Not started")
    .accessibilityHint(step.line)
  }
}
```

- [ ] **Step 3: Wire up `HomeScreen`**

Add state, and helpers at the bottom of the struct:

```swift
  @State private var guided: GuidedStartCoordinator?

  private func guidedTab(for tab: HomeTab) -> GuidedTab? {
    switch tab {
    case .dashboard: .dashboard
    case .portfolio: .portfolio
    case .expenses: .expenses
    default: nil
    }
  }

  private func homeTab(for tab: GuidedTab) -> HomeTab {
    switch tab {
    case .dashboard, .goalPlanning: .dashboard
    case .portfolio: .portfolio
    case .expenses: .expenses
    }
  }
```

Then append these modifiers to the `VStack(spacing: 0) { … }` in `body`, after `.appAnimation(AppMotion.structural, value: billingManager.shouldShowTrialEndedBanner)`:

```swift
    .guidedSpotlight(step: guided?.activeStep, activeTab: guidedTab(for: selectedTab), onSkip: { guided?.skip() })
    .environment(guided)
    .environment(\.norviqReopenGuidedStart, guided.map { coordinator in
      {
        selectedTab = .dashboard
        Task { await coordinator.showMeAround() }
      }
    })
    .task {
      guard guided == nil else { return }
      let coordinator = GuidedStartCoordinator.live()
      guided = coordinator
      await coordinator.refresh()
    }
    .onChange(of: guided?.requestedTab) { _, requested in
      guard let requested else { return }
      selectedTab = homeTab(for: requested)
    }
```

- [ ] **Step 4: Card, goal hop and goal cover in `DashboardRoot`**

1. In `DashboardRoot`, add `@Environment(GuidedStartCoordinator.self) private var guided: GuidedStartCoordinator?`.
2. Replace the `.fullScreenCover(isPresented: $isGoalPlanningPresented) { … }` block with:
   ```swift
         .fullScreenCover(isPresented: $isGoalPlanningPresented) {
           NavigationStack {
             GoalPlanningScreen()
           }
           // Anchors do not leave a presentation, so the cover spotlights its own.
           .guidedSpotlight(step: guided?.activeStep, activeTab: .goalPlanning, onSkip: { guided?.skip() })
           .environment(guided)
         }
   ```
3. In `DashboardContentSection`, add `@Environment(GuidedStartCoordinator.self) private var guided: GuidedStartCoordinator?` and a computed property:
   ```swift
     private var isGuidedCardVisible: Bool { guided?.isCardVisible ?? false }
   ```
4. Put the card at the top of its `VStack(spacing: 20) {`, before `DashboardHeroCard(`:
   ```swift
         if let guided, guided.isCardVisible {
           GuidedStartCard(
             progress: guided.progress,
             message: guided.inlineMessage,
             onSelect: { step in Task { await guided.start(step) } },
             onDismiss: { Task { await guided.dismissCard() } }
           )
           .onAppear { guided.noteCardShown() }
         }
   ```
5. Replace `NewsTickerStrip(viewModel: newsTickerViewModel)` with:
   ```swift
         if !isGuidedCardVisible {
           NewsTickerStrip(viewModel: newsTickerViewModel)
         }
   ```
6. Replace `GoalPlanningDashboardCard(action: onGoalPlanningTap)` with:
   ```swift
         GoalPlanningDashboardCard(action: onGoalPlanningTap)
           .guidedTarget(.goalCard, in: .dashboard)
   ```

- [ ] **Step 5: Mark the targets and the local actions**

**Portfolio**
- `PortfolioListContent.swift`: after `.accessibilityIdentifier("portfolio.addPositionButton")`, add `.guidedTarget(.holdingAdd, in: .portfolio)`.
- `PortfolioScreen.swift`:
  - Add `@Environment(GuidedStartCoordinator.self) private var guided: GuidedStartCoordinator?`.
  - Change `.sheet(isPresented: $isAddPositionPresented) {` to `.sheet(isPresented: $isAddPositionPresented, onDismiss: { guided?.noteUserAction(.addHolding) }) {`.

**Expenses**
- `ExpensesPlannerScreen.swift`:
  - Add the same `@Environment` line.
  - Add `.guidedTarget(.budgetSalary, in: .expenses)` after the `EmptyStateView(…)` initializer's closing parenthesis.
  - Add `.guidedTarget(.budgetSalary, in: .expenses)` after `.controlSize(.small)` on the `Button(viewModel.selectedMonthSnapshot == nil ? "Create" : "Set")`.
  - Change `.sheet(isPresented: $isSalaryEditorPresented, content: salaryEditorSheet)` to `.sheet(isPresented: $isSalaryEditorPresented, onDismiss: { guided?.noteUserAction(.setBudget) }, content: salaryEditorSheet)`.

**Goal planning**
- `GoalPlanningScreen.swift`:
  - Add the same `@Environment` line.
  - Add `.guidedTarget(.goalCreate, in: .goalPlanning)` after `.buttonStyle(.borderedProminent)` on `Button("Create your first goal")`.
  - Add `.guidedTarget(.goalCreate, in: .goalPlanning)` after `.accessibilityHint(…)` on the toolbar `Button("New goal", …)`. Toolbar anchors may not propagate; the empty-state button is the one new users see.
  - Change `.sheet(isPresented: $isCreatingGoal) {` to `.sheet(isPresented: $isCreatingGoal, onDismiss: { guided?.noteUserAction(.setGoal) }) {`.

**Settings**
- `UserProfileView.swift`:
  - Add `@Environment(\.norviqReopenGuidedStart) private var reopenGuidedStart`.
  - In `Section(LocalizedStringKey("Support")) {`, add as the first row:
    ```swift
                    if let reopenGuidedStart {
                        Button {
                            reopenGuidedStart()
                            dismiss()
                        } label: {
                            Label(LocalizedStringKey("Show me around"), systemImage: "sparkles")
                        }
                    }
    ```

- [ ] **Step 6: Build and run the full iOS suite**

Run: `make ios-test`
Expected: PASS. The build has no warnings about unused `guided` in views that only pass it through.

- [ ] **Step 7: Check it by hand on the simulator**

Launch against a local backend (Task 2 or 3 running with `swift run`), using a fresh account that has finished the funnel. Then:
- Confirm the card shows at the top of Home and the news ticker is hidden.
- Tap "Add a holding": the Portfolio tab opens, the "Add Position" button sits in the hole, and the rest is dimmed.
- Add AAPL: the step completes and the card reads 1 of 3.
- Tap "Set a goal": the goal card on Home sits in the hole. Tap it, and inside the cover "Create your first goal" sits in the hole.
- Dismiss the card with ×, then use Settings › Show me around: the card returns.
- Turn on Settings › Accessibility › Reduce Motion and repeat one step: the transitions do not animate.

- [ ] **Step 8: Commit**

```bash
git add financeplan/Features financeplanTests
git commit -m "feat(guided-start): Home card, spotlight overlays, targets and Show me around on iOS"
```

---

### Task 11: Release, merge order and end-to-end check

**Files:**
- Modify: `norviq-backend-guided/Package.swift` and `Package.resolved`; `norviq-ios-guided/financeplan.xcodeproj/project.pbxproj` and its `Package.resolved`

Order matters. **Web must not deploy before the backend is serving `/v1/onboarding`.** The web gate fails closed, so without the endpoint every signed-in web user would land in the funnel.

- [ ] **Step 1: Shared.** Push `feat/guided-start` and open the PR. The user merges it. Then:
  ```bash
  git -C norviq-shared checkout main && git -C norviq-shared pull
  make -C norviq-shared release VERSION=v5.13.0
  ```
- [ ] **Step 2: Backend pin.** In `norviq-backend-guided/Package.swift`, change `exact: "5.12.0"` to `exact: "5.13.0"`. Then:
  ```bash
  swift package resolve && make backend-test
  git commit -am "chore: pin norviq-shared 5.13.0"
  ```
  Push and open the PR. The user merges it; merging to `main` deploys through ArgoCD.
- [ ] **Step 3: Confirm the backend is live** before touching web:
  ```bash
  KUBECONFIG=~/.kube/maat.yaml kubectl -n <norviq backend namespace> rollout status deploy/<norviq backend deployment>
  curl -s -o /dev/null -w '%{http_code}\n' https://api.norviq.org/v1/onboarding
  ```
  Expected: rollout complete, and `401` (the route exists and needs auth), not `404`. Look up the namespace and deployment names in `platform/infra/argocd/apps`.
- [ ] **Step 4: Web.** Push and open the PR. The user merges it. Then check by hand with a production test account: sign in, you land on `/dashboard`, and existing accounts see no card (they were backfilled as dismissed).
- [ ] **Step 5: iOS pin.**
  1. In Xcode, remove the local `norviq-shared-guided` package reference.
  2. Set the `norviq-shared` requirement to exact `5.13.0` (the pbxproj `version = 5.13.0;`) and run File › Packages › Resolve.
  3. Run `make ios-test`.
  4. Commit, push and open the PR. The user merges it.
- [ ] **Step 6: End-to-end check** (fresh production account, both platforms)
  1. Sign up on web and stop at the budget step. Sign in on iOS: the import flow shows. Sign back in on web: `/onboarding/budget`.
  2. Finish the funnel on web: the card shows, 0 of 3.
  3. Start "Add a holding" on web, then add a holding on iOS: web's step completes. In PostHog, `guided_start_step_completed` has `completed_elsewhere: true`.
  4. Dismiss on iOS: after a refresh, web no longer shows the card.
  5. Settings › Show me around on web: the card returns with the right progress.
  6. Complete all three steps: the completed card shows once, and `guided_start_completed` fires once. On the next session, no card.
  7. With an existing (pre-launch) account: no funnel, no card. Show me around shows the backfilled progress.
  8. In PostHog live events, the sequence from 3–6 appears for both `$lib` values.
- [ ] **Step 7: Clean up the worktrees** once all PRs are merged:
  ```bash
  cd ~/Work/production/apps/norviq
  for repo in norviq-shared norviq-backend norviq-web; do git -C "$repo" worktree remove "../${repo}-guided"; done
  git -C norviq-ios/financeplan worktree remove ../../norviq-ios-guided
  ```
