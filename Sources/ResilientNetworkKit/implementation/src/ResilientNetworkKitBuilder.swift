
import Foundation
import ResilientNetworkKit

// MARK: - ResilientNetworkKitBuilder

public final class ResilientNetworkKitBuilder {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  @discardableResult
  public func withNetworkLogTracker(_ tracker: NetworkLogTracker) -> Self {
    networkLogTracker = tracker
    return self
  }

  @discardableResult
  public func withSessionDelegate(_ configuration: SessionDelegateConfiguration) -> Self {
    sessionDelegateConfiguration = configuration
    return self
  }

  @discardableResult
  public func withErrorInterceptor(_ interceptor: ErrorInterceptor) -> Self {
    errorInterceptor = interceptor
    return self
  }

  @discardableResult
  public func withResponseMonitorInterceptor(_ interceptor: ResponseMonitorInterceptor) -> Self {
    responseMonitorInterceptor = interceptor
    return self
  }

  @discardableResult
  public func withNetworkTraceInspector(_ inspector: NetworkTraceInspector?) -> Self {
    networkTraceInspector = inspector
    return self
  }

  @discardableResult
  public func withTokenRefreshingInterceptor(_ interceptor: TokenRefreshingInterceptor) -> Self {
    tokenRefreshingInterceptor = interceptor
    return self
  }

  @discardableResult
  public func withCircuitBreakerConfig(_ config: CircuitBreakerConfiguration?) -> Self {
    circuitBreakerConfig = config
    return self
  }

  @discardableResult
  public func withAdvancedRetryInterceptor(_ interceptor: AdvancedRetryInterceptor?) -> Self {
    advancedRetryInterceptor = interceptor
    return self
  }

  @discardableResult
  public func addRequestInterceptors(_ interceptors: [RequestInterceptor]) -> Self {
    requestInterceptors.append(contentsOf: interceptors)
    return self
  }

  public func build() -> ResilientNetworkKit {
    let monitor = responseMonitorInterceptor ?? ResponseMonitorInterceptorImp(networkLogTracker: networkLogTracker)

    var networkKit: ResilientNetworkKit = ResilientNetworkKitImp(
      session: createURLSession(),
      requestInterceptors: requestInterceptors,
      responsePipeline: createResponsePipeline(responseMonitorInterceptor: monitor),
      networkTraceInspector: networkTraceInspector)

    if let advancedRetry = advancedRetryInterceptor {
      networkKit = AdvancedRetryNetworkKit(
        networkKit: networkKit,
        advancedRetryInterceptor: advancedRetry,
        networkLogTracker: networkLogTracker)
    }

    if let circuitBreaker = circuitBreakerConfig {
      networkKit = CircuitBreakerNetworkKit(
        networkKit: networkKit,
        configuration: circuitBreaker,
        networkLogTracker: networkLogTracker,
        networkTraceInspector: networkTraceInspector)
    }

    if let tokenRefresh = tokenRefreshingInterceptor {
      networkKit = AuthTokenNetworkKit(
        networkKit: networkKit,
        tokenRefreshingInterceptor: tokenRefresh,
        networkLogTracker: networkLogTracker,
        networkTraceInspector: networkTraceInspector)
    }

    return networkKit
  }

  // MARK: Private

  private var networkLogTracker: NetworkLogTracker = NetworkLogTrackerImp()
  private var sessionDelegateConfiguration: SessionDelegateConfiguration = .default
  private var requestInterceptors: [RequestInterceptor] = []
  private var errorInterceptor: ErrorInterceptor = ErrorInterceptorImp()
  private var responseStatusInterceptor: ResponseStatusInterceptor = ResponseStatusInterceptorImp()
  private var responseErrorInspector: ResponseErrorInspector = ResponseErrorInspectorImp()
  private var responseParserInterceptor: ResponseParserInterceptor = ResponseParserInterceptorImp()
  private var conflictJustifier: ConflictJustifier = ConflictJustifierImp()
  private var redirectInterceptor: RedirectInterceptor = RedirectInterceptorImp()
  private var responseMonitorInterceptor: ResponseMonitorInterceptor?
  private var networkTraceInspector: NetworkTraceInspector?

  private var tokenRefreshingInterceptor: TokenRefreshingInterceptor?
  private var circuitBreakerConfig: CircuitBreakerConfiguration?
  private var advancedRetryInterceptor: AdvancedRetryInterceptor?

  // MARK: - Private Helpers

  private func createURLSession() -> NetworkKitSession {
    switch sessionDelegateConfiguration {
    case let .customSessionDelegate(delegate, configuration):
      return URLSessionFactory(delegate: delegate, configuration: configuration).session
    case let .defaultSession(sslConfig, metricInterceptors, urlSessionConfig):
      let securityTrust = createSecurityTrust(identities: sslConfig.pinnedHostIdentities)
      let sessionDelegate = SessionDelegate(
        metricInterceptors: metricInterceptors,
        isPinningEnabled: sslConfig.isPinningEnabled,
        sslPinningInterceptor: SSLPinningInterceptorImp(securityTrust: securityTrust),
        redirectInterceptor: redirectInterceptor)
      return URLSessionFactory(delegate: sessionDelegate, configuration: urlSessionConfig).session
    }
  }

  private func createSecurityTrust(identities: [SSLHostIdentity]) -> SecurityTrust {
    SecurityTrustImp(
      sslPinning: SSLPinningImp(identities: identities),
      networkLogTracker: networkLogTracker,
      trustProvider: SecTrustProviderImp())
  }

  private func createResponsePipeline(responseMonitorInterceptor: ResponseMonitorInterceptor) -> ResponseInterceptingPipeline {
    ResponseInterceptingPipelineImp(
      errorInterceptor: errorInterceptor,
      responseStatusInterceptor: responseStatusInterceptor,
      conflictJustifier: conflictJustifier,
      responseErrorInspector: responseErrorInspector,
      responseParserInterceptor: responseParserInterceptor,
      responseMonitorInterceptor: responseMonitorInterceptor)
  }
}
