import Foundation

// MARK: - SSLPinningInterceptor

public protocol SSLPinningInterceptor {
  func verifyIdentity(_ protectionSpace: URLProtectionSpace) -> AuthChallengeDecision
}

// MARK: - SSLPinningInterceptorImp

public final class SSLPinningInterceptorImp: SSLPinningInterceptor {
  // MARK: Lifecycle

  public init(securityTrust: SecurityTrust) {
    self.securityTrust = securityTrust
  }

  // MARK: Public

  public func verifyIdentity(_ protectionSpace: URLProtectionSpace) -> AuthChallengeDecision {
    securityTrust.verifyServerTrust(with: protectionSpace)
  }

  // MARK: Private

  private let securityTrust: SecurityTrust
}
