import Foundation

/// @mockable
/// A protocol that allows clients to define custom retry logic for specific condition.
///
/// This interceptor provides a way to customize retry policies based on the error received
/// from a network request. Clients can implement this protocol to specify retry conditions
/// for particular errors, such as server errors (e.g., 503 Service Unavailable or 504 Gateway Timeout),
/// or any other condition where a retry might be appropriate.
///
/// The `getRetryPolicy(_:error:)` method allows the client to define a `RetryPolicy` based on
/// the endpoint and the specific error returned. If no retry policy is returned (i.e., `nil`),
/// the request will not be retried.
///
/// Example Usage:
/// ```swift
/// class MyAdvancedRetryInterceptor: AdvancedRetryInterceptor {
///     func getRetryPolicy<E: Endpoint>(_ endPoint: E, error: ResilientNetworkKitError) -> RetryPolicy? {
///         // Retry on 503 or 504 errors with exponential backoff
///         switch error.statusCode {
///         case 503, 504:
///             return .exponentialBackoff
///         default:
///             return nil
///         }
///     }
/// }
/// ```
///
/// - Note: This protocol provides flexibility for clients to define retry behavior for various
///         network error scenarios based on their specific requirements.
public protocol AdvancedRetryInterceptor: AnyObject, Sendable {
  /// Returns a `RetryPolicy` for the given `Endpoint` and `ResilientNetworkKitError`, if retry is appropriate.
  ///
  /// - Parameters:
  ///   - endPoint: The endpoint that was called.
  ///   - error: The error received from the network request.
  /// - Returns: A `RetryPolicy` to use for retrying the request, or `nil` if no retry should occur.
  func getRetryPolicy(_ endPoint: some Endpoint, error: ResilientNetworkKitError) -> RetryPolicy?
}
