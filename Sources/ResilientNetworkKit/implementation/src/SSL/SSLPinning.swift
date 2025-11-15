import CommonCrypto
import Foundation

// MARK: - SSLPinning

public protocol SSLPinning {
  func isPinned(_ host: String) -> Bool
  func verify(_ host: String, receivedKey: Data) -> SSLPinningResult
}

// MARK: - SSLPinningImp

public final class SSLPinningImp: SSLPinning {
  // MARK: Lifecycle

  public init(identities: [SSLHostIdentity]) {
    self.identities = identities
  }

  // MARK: Public

  public func isPinned(_ host: String) -> Bool {
    obtainIdentity(for: host) != nil
  }

  public func verify(_ host: String, receivedKey: Data) -> SSLPinningResult {
    guard let identity = obtainIdentity(for: host) else { return .undefinedHost }

    let serverKey = spkiHash(from: receivedKey).base64EncodedString()
    guard identity.keys().contains(serverKey) else { return .failure }

    return .success
  }

  // MARK: Private

  private let identities: [SSLHostIdentity]
}

// MARK: - Private

private extension SSLPinningImp {
  func obtainIdentity(for host: String) -> SSLHostIdentity? {
    identities.first(where: { $0.host.contains(host) })
  }

  func spkiHash(from rsa2048Key: Data) -> Data {
    let rsa2048ASN1HeaderBytes: [UInt8] = [
      0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86,
      0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00,
    ]
    let rsa2048ASN1HeaderSize
      = MemoryLayout.size(ofValue: rsa2048ASN1HeaderBytes[0])
      * rsa2048ASN1HeaderBytes.count

    var dataWithHeader = Data(bytes: rsa2048ASN1HeaderBytes, count: rsa2048ASN1HeaderSize)
    dataWithHeader.append(rsa2048Key)

    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    dataWithHeader.withUnsafeBytes { rawBufferPointer in
      _ = CC_SHA256(rawBufferPointer.baseAddress, CC_LONG(dataWithHeader.count), &hash)
    }

    return Data(hash)
  }
}
