import Foundation

// MARK: - TokenRefreshingInterceptor

/// @mockable
public protocol TokenRefreshingInterceptor: AnyObject, Sendable {
  func refreshAccessToken(completion: @Sendable @escaping (Result<Void, ResilientNetworkKitError>) -> Void)
}

public extension TokenRefreshingInterceptor {
  func refreshAccessTokenAsync() async throws {
    try await withCheckedThrowingContinuation { continuation in
      refreshAccessToken { result in
        switch result {
        case .success:
          continuation.resume()
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
