import Foundation

/// A protocol for handling HTTP 409 Conflict responses.
/// @mockable
public protocol ConflictJustifier: Sendable {
  func justify(payload data: Data?) -> ResilientNetworkKitError
}
