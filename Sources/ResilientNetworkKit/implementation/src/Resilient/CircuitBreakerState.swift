import Foundation

enum CircuitBreakerState: Equatable {
  case closed
  case open(Date)
  case halfOpen

  // MARK: Internal

  static func == (lhs: CircuitBreakerState, rhs: CircuitBreakerState) -> Bool {
    switch (lhs, rhs) {
    case (.closed, .closed):
      return true
    case let (.open(lhsDate), .open(rhsDate)):
      return lhsDate == rhsDate
    case (.halfOpen, .halfOpen):
      return true
    default:
      return false
    }
  }
}
