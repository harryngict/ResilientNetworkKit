import Foundation
import ResilientNetworkKit

open class RedirectInterceptorImp: RedirectInterceptor {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func verifyRedirect(from originalRequest: URLRequest?,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void)
  {
    completionHandler(request)
  }
}
