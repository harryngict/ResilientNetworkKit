import Foundation

// MARK: - URLSessionFactory

/// Session Factory to create default session object with
/// default settings
final class URLSessionFactory {
  // MARK: Lifecycle

  init(delegate: SessionDelegate,
       configuration: URLSessionConfiguration)
  {
    self.delegate = delegate
    self.configuration = configuration
  }

  // MARK: Internal

  let delegate: SessionDelegate
  let configuration: URLSessionConfiguration

  lazy var session = URLSession(
    configuration: configuration,
    delegate: delegate,
    delegateQueue: OperationQueue.main)
}
