import Foundation

// MARK: - SecTrustProvider

public protocol SecTrustProvider {
  var hasCertificate: Bool { get }
  func assignSecTrust(_ trust: SecTrust)
  func provideCertificate() -> SecCertificate?
  func providePublicKey(for certificate: SecCertificate) -> Data?
  func isHostTrusted(host: String) -> Bool
}

// MARK: - SecTrustProviderImp

public final class SecTrustProviderImp: SecTrustProvider {
  // MARK: Lifecycle

  public init(secTrust: SecTrust? = nil) {
    self.secTrust = secTrust
  }

  // MARK: Public

  public var hasCertificate: Bool {
    guard let trust = secTrust else { return false }
    return SecTrustGetCertificateCount(trust) > 0
  }

  public func assignSecTrust(_ trust: SecTrust) {
    secTrust = trust
  }

  public func provideCertificate() -> SecCertificate? {
    guard hasCertificate, let trust = secTrust else { return nil }

    if #available(iOS 15.0, *) {
      let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
      return chain?.first
    } else {
      return SecTrustGetCertificateAtIndex(trust, 0)
    }
  }

  public func providePublicKey(for certificate: SecCertificate) -> Data? {
    guard let trust = secTrust else { return nil }

    var error: CFError?
    guard
      SecTrustEvaluateWithError(trust, &error),
      let key = SecTrustCopyKey(trust) else
    {
      return nil
    }
    return extractPublicKeyData(key)
  }

  public func isHostTrusted(host: String) -> Bool {
    guard let trust = secTrust else { return false }
    let policy = SecPolicyCreateSSL(true, host as CFString)
    SecTrustSetPolicies(trust, policy)
    var error: CFError?
    return SecTrustEvaluateWithError(trust, &error)
  }

  // MARK: Private

  private var secTrust: SecTrust?
}

private extension SecTrustProviderImp {
  func extractPublicKeyData(_ rsaKey: SecKey?) -> Data? {
    guard let key = rsaKey else {
      return nil
    }
    guard let pubAttributes = SecKeyCopyAttributes(key) as? [String: Any] else {
      return nil
    }
    guard pubAttributes[String(kSecAttrKeyType)] as? String == String(kSecAttrKeyTypeRSA) else {
      return nil
    }
    guard pubAttributes[String(kSecAttrKeyClass)] as? String == String(kSecAttrKeyClassPublic) else {
      return nil
    }
    return pubAttributes[kSecValueData as String] as? Data
  }
}
