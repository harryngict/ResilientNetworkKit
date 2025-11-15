import Foundation

/// @mockable
public protocol ErrorInterceptor: Sendable {
  func intercept(_ error: Error?, endpoint: some Endpoint) -> ResilientNetworkKitError?
}
