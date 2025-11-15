import Foundation

// MARK: - SecurityTrust

public protocol SecurityTrust {
  func verifyServerTrust(with protectionSpace: URLProtectionSpace) -> AuthChallengeDecision
}

// MARK: - SecurityTrustImp

public final class SecurityTrustImp: SecurityTrust {
  // MARK: Lifecycle

  public init(sslPinning: SSLPinning,
              networkLogTracker: NetworkLogTracker,
              trustProvider: SecTrustProvider)
  {
    self.sslPinning = sslPinning
    self.networkLogTracker = networkLogTracker
    self.trustProvider = trustProvider
  }

  // MARK: Public

  public func verifyServerTrust(with protectionSpace: URLProtectionSpace) -> AuthChallengeDecision {
    let host = protectionSpace.host
    guard
      let serverTrust: SecTrust = protectionSpace.serverTrust,
      shouldPinCertificate(with: protectionSpace) else
    {
      networkLogTracker.infor(
        ResilientNetworkKitConstants.loggingTag,
        "No SSL Pinning is required for \'\(host)\'. Proceed.")
      return Decision.default
    }

    trustProvider.assignSecTrust(serverTrust)

    guard
      let certificate = trustProvider.provideCertificate(),
      let serverKey = trustProvider.providePublicKey(for: certificate) else
    {
      networkLogTracker.warning(
        ResilientNetworkKitConstants.loggingTag,
        "SERVER KEY not found for \'\(host)\'. Handshake aborted.")
      return Decision.cancel
    }

    guard sslPinning.verify(host, receivedKey: serverKey) == .success else {
      networkLogTracker.warning(
        ResilientNetworkKitConstants.loggingTag,
        "SSL Pinning failed for \'\(host)\'. Handshake aborted.")
      return Decision.cancel
    }

    if !trustProvider.isHostTrusted(host: host) {
      networkLogTracker.warning(
        ResilientNetworkKitConstants.loggingTag,
        "Server is not trusted! (\'\(host)\'). Proceed.")
    }

    return AuthChallengeDecision(
      .useCredential,
      URLCredential(trust: serverTrust))
  }

  // MARK: Private

  private let sslPinning: SSLPinning
  private let networkLogTracker: NetworkLogTracker
  private let trustProvider: SecTrustProvider
}

// MARK: - Private

private extension SecurityTrustImp {
  func shouldPinCertificate(with protectionSpace: URLProtectionSpace) -> Bool {
    guard sslPinning.isPinned(protectionSpace.host) else { return false }
    let isSecTrustValidationRequired = (protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
    return isSecTrustValidationRequired
  }
}
