import Foundation
import ResilientNetworkKit

open class ErrorInterceptorImp: @unchecked Sendable, ErrorInterceptor {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func intercept(_ error: Error?,
                      endpoint: some Endpoint)
    -> ResilientNetworkKitError?
  {
    guard let error else {
      return nil
    }

    let nsError = error as NSError
    let isCancelled = nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled

    let isTimedOut = nsError.code == NSURLErrorTimedOut
    let notConnectedToInternet = nsError.code == NSURLErrorNotConnectedToInternet

    if isCancelled {
      return ResilientNetworkKitError.canceled
    } else if isTimedOut || notConnectedToInternet {
      return ResilientNetworkKitError.networkError(error: nsError)
    }

    return ResilientNetworkKitError.unknown(error: nsError)
  }
}
