import Foundation

// MARK: - AuthChallengeDecision

public struct AuthChallengeDecision: Sendable, Equatable {
  // MARK: Lifecycle

  init(_ authChallenge: URLSession.AuthChallengeDisposition,
       _ credential: URLCredential? = nil)
  {
    self.authChallenge = authChallenge
    self.credential = credential
  }

  // MARK: Internal

  let authChallenge: URLSession.AuthChallengeDisposition
  let credential: URLCredential?
}

// MARK: - Decision

enum Decision {
  static let `default`: AuthChallengeDecision = .init(.performDefaultHandling)
  static let cancel: AuthChallengeDecision = .init(.cancelAuthenticationChallenge)
}
