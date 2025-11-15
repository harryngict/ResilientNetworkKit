import Foundation

/// @mockable
public protocol RedirectInterceptor {
  func verifyRedirect(from originalRequest: URLRequest?,
                      newRequest request: URLRequest,
                      completionHandler: @escaping (URLRequest?) -> Void)
}
