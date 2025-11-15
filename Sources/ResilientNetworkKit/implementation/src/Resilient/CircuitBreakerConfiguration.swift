import Foundation

public struct CircuitBreakerConfiguration: Decodable {
  // MARK: Lifecycle

  public init(failureThreshold: Int = 8,
              openTimeout: Double = 15,
              halfOpenMaxRequests: Int = 3)
  {
    self.failureThreshold = failureThreshold
    self.openTimeout = openTimeout
    self.halfOpenMaxRequests = halfOpenMaxRequests
  }

  // MARK: Internal

  let failureThreshold: Int
  let openTimeout: Double
  let halfOpenMaxRequests: Int
}
