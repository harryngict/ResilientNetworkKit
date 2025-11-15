import Foundation
import ResilientNetworkKit

// MARK: - SessionDelegateConfiguration

public enum SessionDelegateConfiguration {
  case defaultSession(
    sslConfiguration: SSLConfiguration,
    metricInterceptors: [MetricInterceptor],
    urlSessionConfiguration: URLSessionConfiguration = URLSessionDefaultConfiguration.default)

  case customSessionDelegate(
    sessionDelegate: SessionDelegate,
    urlSessionConfiguration: URLSessionConfiguration = URLSessionDefaultConfiguration.default)

  // MARK: Public

  public static var `default`: SessionDelegateConfiguration {
    SessionDelegateConfiguration.defaultSession(
      sslConfiguration: SSLConfiguration(isPinningEnabled: false, pinnedHostIdentities: []),
      metricInterceptors: [],
      urlSessionConfiguration: URLSessionDefaultConfiguration.default)
  }
}

// MARK: - URLSessionDefaultConfiguration

public enum URLSessionDefaultConfiguration {
  public static var `default`: URLSessionConfiguration {
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.waitsForConnectivity = true
    sessionConfig.allowsCellularAccess = true
    sessionConfig.httpShouldUsePipelining = true
    sessionConfig.timeoutIntervalForRequest = 60.0
    sessionConfig.requestCachePolicy = .reloadRevalidatingCacheData
    sessionConfig.urlCache = URLCache.shared

    return sessionConfig
  }
}
