import Foundation

/// @mockable
public protocol ResponseParserInterceptor: Sendable {
  func intercept<E: Endpoint>(_ data: Data?, endpoint: E) throws -> E.Response
}
