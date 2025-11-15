# ResilientNetworkKit

A production-ready, **resilient networking toolkit** for iOS built on top of `URLSession`.

ResilientNetworkKit is designed for real-world mobile apps where failures are normal – flaky networks,
expired tokens, back-end incidents, and SSL requirements. It gives you:

- **A clean `Endpoint` abstraction** so you can build a NetworkKit quickly and keep request logic consistent.
- **Full control & observability** of all network traffic via metrics, logging, SSL pinning and interceptors.
- **Advanced resilience patterns** out of the box: advanced retry, token refresh, and circuit breaker.

---

## Why this library? (Pain points & solutions)

### 1. Build a robust NetworkKit quickly

**Pain points**
- Every project re-invents a networking layer around `URLSession`.
- Hard to keep request definitions consistent across teams and modules.
- Setting up retries, timeouts, parsing, and priorities often ends up as scattered code.

**How ResilientNetworkKit helps**
- A single, strongly-typed `Endpoint` protocol for all requests.
- A `ResilientNetworkKit` protocol that abstracts sending requests (async/await or completion).
- A fluent `ResilientNetworkKitBuilder` to assemble your NetworkKit instance in a few lines.

### 2. Control all network traffic via metrics, SSL and interceptors

**Pain points**
- No unified way to observe performance and errors across all requests.
- SSL pinning is tricky to get right and easy to forget.
- Different teams need different logging & metrics pipes (e.g. Datadog, Firebase, internal tools).

**How ResilientNetworkKit helps**
- **Metrics** via `MetricInterceptor` and `URLSessionTaskMetricsProtocol` for latency, bytes sent/received, etc.
- **SSL pinning** via `SSLConfiguration` and `SSLHostIdentity`, implemented safely in `SecurityTrustImp`.
- **Logging** via `NetworkLogTracker` and customizable `ResponseMonitorInterceptor`.
- **Traceability** via `NetworkTraceInspector` & `NetworkRequestStatus` to reconstruct any request.

### 3. Advanced networking: advanced retry, refresh token, circuit breaker

**Pain points**
- Handling refresh token flows correctly is hard and easy to race-condition.
- Blanket retry policies can overload struggling backends.
- Without a circuit breaker, your app keeps hammering a broken service.

**How ResilientNetworkKit helps**
- **Advanced retry per error/endpoint** via `AdvancedRetryInterceptor` and `RetryPolicy`.
- **Centralized token refresh** via `TokenRefreshingInterceptor` and `AuthTokenNetworkKit`.
- **Circuit breaker** via `CircuitBreakerConfiguration` & `CircuitBreakerNetworkKit` to protect your backend
  and fail fast when a service is clearly unhealthy.

---

## Core concepts

### `Endpoint`

Define every request as a value type that conforms to `Endpoint`:

```swift
public protocol Endpoint: Hashable, CustomStringConvertible, Identifiable, Sendable {
  associatedtype Response: Decodable & Sendable
  var id: String { get }
  var url: URL { get }
  var method: HTTPMethod { get }
  var query: [String: AnyHashable] { get set }
  var headers: [String: String] { get set }
  var httpBodyEncoding: HTTPBodyEncoding { get }
  var priority: Float { get }
  var timeout: TimeInterval { get }
  var cachePolicy: URLRequest.CachePolicy { get }
  var responseParser: ResponseParser { get }
  var isRefreshTokenEndpoint: Bool { get }
}
```

### `ResilientNetworkKit` protocol

The main abstraction your app depends on:

```swift
public protocol ResilientNetworkKit: Sendable {
  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType) async throws
    -> (E.Response, Int, ResilientNetworkKitHeaders)

  @Sendable
  func send<E: Endpoint>(_ endpoint: E,
                         retry: RetryPolicy,
                         receiveOn queue: DispatchQueueType,
                         completion: @Sendable @escaping (Result<(E.Response, Int, ResilientNetworkKitHeaders), ResilientNetworkKitError>) -> Void)

  @Sendable
  func cancelAllRequest(completingOn queue: DispatchQueueType, completion: (@Sendable () -> Void)?)
}
```

This is what you inject into view models, controllers and use cases. The implementation (`ResilientNetworkKitImp`
and decorators like `CircuitBreakerNetworkKit`, `AuthTokenNetworkKit`, `AdvancedRetryNetworkKit`) are hidden
behind the protocol.

### `ResilientNetworkKitBuilder`

A fluent builder used to compose the full NetworkKit stack:

- Plug in logging (`NetworkLogTracker`)
- Configure SSL & metrics (`SessionDelegateConfiguration` & `SSLConfiguration`)
- Add request interceptors (`RequestInterceptor`)
- Add advanced behaviors (`AdvancedRetryInterceptor`, `TokenRefreshingInterceptor`, `CircuitBreakerConfiguration`)

---

## Installation

### Swift Package Manager

**Xcode**
1. Go to **File → Add Packages…**
2. Enter the URL of this repository:
   `https://github.com/harryngict/ResilientNetworkKit.git`
3. Add the **ResilientNetworkKit** (and optionally **ResilientNetworkKitImp**, **ResilientNetworkKitMock**) products to your target.

**Package.swift**

```swift
.dependencies: [
  .package(url: "https://github.com/harryngict/ResilientNetworkKit.git", from: "0.1.0"),
],
.targets: [
  .target(
    name: "YourFeature",
    dependencies: [
      .product(name: "ResilientNetworkKit", package: "ResilientNetworkKit"),
      .product(name: "ResilientNetworkKitImp", package: "ResilientNetworkKit"),
    ]
  ),
]
```

### CocoaPods

```ruby
# Podfile
source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'

use_frameworks!

pod 'ResilientNetworkKit',     :git => 'https://github.com/harryngict/ResilientNetworkKit.git'
pod 'ResilientNetworkKitImp',  :git => 'https://github.com/harryngict/ResilientNetworkKit.git'
# Optional – for tests
pod 'ResilientNetworkKitMock', :git => 'https://github.com/harryngict/ResilientNetworkKit.git'
```

Then run:

```bash
pod install
```

---

## Quick start

### 1. Define an `Endpoint`

```swift
import ResilientNetworkKit

struct UsersEndpoint: Endpoint, @unchecked Sendable {
  typealias Response = [User]

  var query: [String : AnyHashable] = [:]
  var headers: [String : String] = [:]

  var url: URL { URL(string: "https://jsonplaceholder.typicode.com/users")! }
  var method: HTTPMethod { .get }
}
```

### 2. Build your `ResilientNetworkKit` instance

```swift
import ResilientNetworkKit
import ResilientNetworkKitImp

final class AppNetworkProvider {
  let networkKit: ResilientNetworkKit

  init() {
    let logger = NetworkLogTrackerImp()

    let builder = ResilientNetworkKitBuilder()
    networkKit = builder
      .withNetworkLogTracker(logger)
      .withSessionDelegate(.default) // SSL off by default, metrics off by default
      .withResponseMonitorInterceptor(ClientResponseMonitorInterceptorImp(networkLogTracker: logger))
      .withNetworkTraceInspector(nil) // or your implementation
      .withTokenRefreshingInterceptor(self) // implements TokenRefreshingInterceptor
      .withCircuitBreakerConfig(CircuitBreakerConfiguration())
      .withAdvancedRetryInterceptor(AdvancedRetryInterceptorImp())
      .addRequestInterceptors([AuthHeaderInterceptor()])
      .build()
  }
}
```

Where `AuthHeaderInterceptor` is a simple `RequestInterceptor`:

```swift
import ResilientNetworkKit

final class AuthHeaderInterceptor: RequestInterceptor {
  func modify<E: Endpoint>(endpoint: E) -> E {
    var copy = endpoint
    copy.headers["Authorization"] = "Bearer <token>"
    return copy
  }
}
```

### 3. Send a request (async/await)

```swift
let endpoint = UsersEndpoint()

Task {
  do {
    let (users, statusCode, headers) = try await networkKit.send(
      endpoint,
      retry: .constant(count: 2, delay: 1.0)
    )
    print("Loaded", users.count, "users", "status:", statusCode)
  } catch {
    print("Networking failed", error)
  }
}
```

### 4. Or use completion-based APIs

```swift
networkKit.send(UsersEndpoint(), retry: .none) { result in
  switch result {
  case let .success((users, statusCode, _)):
    print("Loaded", users.count, "users", "status:", statusCode)
  case let .failure(error):
    print("Networking failed", error)
  }
}
```

---

## Advanced features

### Advanced retry per error / endpoint

Implement `AdvancedRetryInterceptor` to customize retry based on error or endpoint:

```swift
import ResilientNetworkKit

final class MyAdvancedRetryInterceptor: AdvancedRetryInterceptor {
  func getRetryPolicy(_ endPoint: some Endpoint, error: ResilientNetworkKitError) -> RetryPolicy? {
    // Retry 5 times with 5s delay on 503/504 only
    guard [503, 504].contains(error.statusCode) else { return nil }
    return .constant(count: 5, delay: 5.0)
  }
}
```

Then plug it into the builder:

```swift
.withAdvancedRetryInterceptor(MyAdvancedRetryInterceptor())
```

### Automatic token refresh

Centralize your refresh token logic with `TokenRefreshingInterceptor`:

```swift
import ResilientNetworkKit

final class TokenRefresher: TokenRefreshingInterceptor {
  private let networkKit: ResilientNetworkKit

  init(networkKit: ResilientNetworkKit) {
    self.networkKit = networkKit
  }

  func refreshAccessToken(completion: @escaping (Result<Void, ResilientNetworkKitError>) -> Void) {
    let refreshEndpoint = RefreshTokenEndpoint()
    networkKit.send(refreshEndpoint) { result in
      switch result {
      case .success:
        // Update your token storage here
        completion(.success(()))
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }
}
```

Attach it:

```swift
.withTokenRefreshingInterceptor(TokenRefresher(networkKit: networkKit))
```

ResilientNetworkKit will:
- Queue requests while a refresh is in progress.
- Retry queued requests once refresh succeeds.

### Circuit breaker

Protect your backend from continuous failures using `CircuitBreakerConfiguration`:

```swift
let circuitConfig = CircuitBreakerConfiguration(
  failureThreshold: 8,
  openTimeout: 15,
  halfOpenMaxRequests: 3
)

let networkKit = ResilientNetworkKitBuilder()
  .withCircuitBreakerConfig(circuitConfig)
  .build()
```

The `CircuitBreakerNetworkKit` decorator will:
- Open the circuit after repeated failures and immediately fail new calls with `.circuitBreakerOpen`.
- Transition back to half-open/closed when conditions improve.

### Metrics, logging & SSL pinning

- Implement `MetricInterceptor` to forward `URLSessionTaskMetrics` to your observability stack.
- Provide `SSLConfiguration(isPinningEnabled:pinnedHostIdentities:)` to enable SSL pinning.
- Implement `NetworkTraceInspector` to store a timeline of requests (for in-app debugging UIs).
- Implement `NetworkLogTracker` to centralize all networking logs.

---

## Testing & mocking

- Use the `ResilientNetworkKit` protocol to inject test doubles anywhere.
- Use the `ResilientNetworkKitMock` module (CocoaPods / SPM product) for generated mocks in unit tests.
- Metrics, interceptors and trace inspectors are all protocols, so they are easy to fake.

---

## Architecture at a glance

- **Interfaces** (`Sources/ResilientNetworkKit/interfaces`): public protocols & value types your app depends on.
- **Implementation** (`Sources/ResilientNetworkKit/implementation`): concrete implementations, decorators and
  builders (`ResilientNetworkKitImp`, circuit breaker, token refresh, retry, SSL, metrics, etc.).
- **Mocks** (`Sources/ResilientNetworkKit/mocks`): mocks tailored for unit testing.

This separation makes the library suitable for large, modular iOS codebases, and friendly to dependency
injection and testing.
