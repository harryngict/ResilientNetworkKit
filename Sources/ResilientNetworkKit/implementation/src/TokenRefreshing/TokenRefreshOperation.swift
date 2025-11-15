import Foundation
import ResilientNetworkKit

// MARK: - TokenRefreshOperation

final class TokenRefreshOperation: Operation, @unchecked Sendable {
  // MARK: Lifecycle

  init(interceptor: TokenRefreshingInterceptor,
       completion: @escaping (Result<Void, ResilientNetworkKitError>) -> Void)
  {
    self.interceptor = interceptor
    self.completion = completion
  }

  // MARK: Internal

  override func main() {
    guard !isCancelled else { return }

    interceptor.refreshAccessToken(completion: { result in
      switch result {
      case .success:
        self.completion(.success(()))
      case let .failure(error):
        self.completion(.failure(error))
      }
    })
  }

  // MARK: Private

  private let interceptor: TokenRefreshingInterceptor
  private let completion: (Result<Void, ResilientNetworkKitError>) -> Void
}
