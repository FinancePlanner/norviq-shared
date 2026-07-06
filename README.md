# StockPlanShared

Shared API models for StockPlan services and clients.

## What this package contains

- Request/response DTOs used by backend APIs
- Platform-agnostic Swift value types only (`Foundation`)

## What this package does not contain

- Vapor/Fluent models, controllers, repositories, migrations
- UI state or app-specific presentation models

## Install from GitHub

### Vapor backend (`Package.swift`)

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/StockPlanShared.git", from: "0.1.0"),
],
targets: [
    .executableTarget(
        name: "StockPlanBackend",
        dependencies: [
            .product(name: "StockPlanShared", package: "StockPlanShared"),
        ]
    )
]
```

### iOS app (Xcode)

1. File > Add Packages...
2. Add `https://github.com/<your-org>/StockPlanShared.git`
3. Add product `StockPlanShared` to your app target

## Versioning

Use semantic versioning and tags:
- `0.x` while contracts are still evolving
- `1.0.0` when contracts are stable

For breaking API changes, release a new major version and update backend + iOS together.
# norviq-shared
