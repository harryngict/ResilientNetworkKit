import Foundation

// MARK: - NetworkKitSession

/// @mockable
protocol NetworkKitSession: Sendable {
  var allTasks: [URLSessionTask] { get async }
  func getAllTasks(completionHandler: @escaping @Sendable ([URLSessionTask]) -> Void)
  func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
}

// MARK: - URLSession + NetworkKitSession

extension URLSession: NetworkKitSession {}
