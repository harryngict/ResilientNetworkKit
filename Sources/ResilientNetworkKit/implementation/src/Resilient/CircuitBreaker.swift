import Foundation
import ResilientNetworkKit

final class CircuitBreaker: @unchecked Sendable {
  // MARK: Lifecycle

  init(configuration: CircuitBreakerConfiguration) {
    failureThreshold = configuration.failureThreshold
    openTimeout = configuration.openTimeout
    halfOpenMaxRequests = configuration.halfOpenMaxRequests
  }

  // MARK: Internal

  func shouldAllowRequest() -> Bool {
    switch state {
    case .closed:
      return true
    case let .open(openedAt):
      let now = Date()
      if now.timeIntervalSince(openedAt) > openTimeout {
        state = .halfOpen
        return true
      }
      return false
    case .halfOpen:
      if halfOpenRequestCount < halfOpenMaxRequests {
        halfOpenRequestCount += 1
        return true
      }
      return false
    }
  }

  func reportSuccess() {
    if state == .halfOpen {
      resetCircuit()
    }
  }

  func reportFailure(error: ResilientNetworkKitError) {
    guard let statusCode = error.statusCode else { return }
    if case .serverError = StatusCode(code: statusCode) {
      failureCount += 1

      if failureCount >= failureThreshold {
        openCircuit()
      }
    }
  }

  // MARK: Private

  private var state: CircuitBreakerState = .closed
  private var failureCount = 0
  private let failureThreshold: Int
  private let openTimeout: TimeInterval
  private let halfOpenMaxRequests: Int
  private var halfOpenRequestCount = 0

  // MARK: Private Methods

  private func openCircuit() {
    state = .open(Date())
    failureCount = 0
  }

  private func resetCircuit() {
    state = .closed
    failureCount = 0
    halfOpenRequestCount = 0
  }
}
