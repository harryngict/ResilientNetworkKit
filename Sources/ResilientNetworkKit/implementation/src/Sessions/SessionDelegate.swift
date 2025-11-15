import Foundation
import ResilientNetworkKit

// MARK: - SessionDelegate

open class SessionDelegate: NSObject, @unchecked Sendable {
  // MARK: Lifecycle

  public init(metricInterceptors: [MetricInterceptor],
              isPinningEnabled: Bool,
              sslPinningInterceptor: SSLPinningInterceptor,
              redirectInterceptor: RedirectInterceptor)
  {
    self.metricInterceptors = metricInterceptors
    self.isPinningEnabled = isPinningEnabled
    self.sslPinningInterceptor = sslPinningInterceptor
    self.redirectInterceptor = redirectInterceptor
  }

  // MARK: Private

  private let metricInterceptors: [MetricInterceptor]
  private let sslPinningInterceptor: SSLPinningInterceptor
  private let redirectInterceptor: RedirectInterceptor
  private let isPinningEnabled: Bool
}

// MARK: URLSessionTaskDelegate

extension SessionDelegate: URLSessionTaskDelegate {
  public func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didFinishCollecting metrics: URLSessionTaskMetrics)
  {
    let dataPoints = URLSessionTaskMetricsImp(taskMetrics: metrics, task: task)
    metricInterceptors.forEach { $0.notify(metrics: dataPoints) }
  }

  public func urlSession(_ session: URLSession,
                         didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    if isPinningEnabled {
      let decision = sslPinningInterceptor.verifyIdentity(challenge.protectionSpace)
      completionHandler(decision.authChallenge, decision.credential)
    } else {
      completionHandler(Decision.default.authChallenge, Decision.default.credential)
    }
  }

  public func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         willPerformHTTPRedirection response: HTTPURLResponse,
                         newRequest request: URLRequest,
                         completionHandler: @escaping (URLRequest?) -> Void)
  {
    redirectInterceptor.verifyRedirect(
      from: task.originalRequest,
      newRequest: request,
      completionHandler: completionHandler)
  }
}
