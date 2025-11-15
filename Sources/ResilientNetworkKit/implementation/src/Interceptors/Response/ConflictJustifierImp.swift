import Foundation
import ResilientNetworkKit

public final class ConflictJustifierImp: ConflictJustifier {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public func justify(payload data: Data?) -> ResilientNetworkKitError {
    let body: [String: Any]
    do {
      guard
        let data,
        let deserialised = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else
      {
        return .conflict(data: [:])
      }
      body = deserialised
    } catch {
      body = [:]
    }

    return .conflict(data: body)
  }
}
