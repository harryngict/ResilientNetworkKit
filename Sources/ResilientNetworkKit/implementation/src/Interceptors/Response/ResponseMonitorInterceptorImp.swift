import Foundation
import ResilientNetworkKit

// MARK: - ResponseMonitorInterceptorImp

open class ResponseMonitorInterceptorImp: @unchecked Sendable, ResponseMonitorInterceptor {
  // MARK: Lifecycle

  public init(networkLogTracker: NetworkLogTracker) {
    self.networkLogTracker = networkLogTracker
  }

  // MARK: Open

  open func monitorResponse(endpoint: some Endpoint,
                            response: HTTPURLResponse?,
                            error: (any Error)?,
                            data: Data?,
                            requestStartTime: TimeInterval,
                            requestEndTime: TimeInterval)
  {
    buildLogMessage(
      endpoint: endpoint,
      response: response,
      requestParams: endpoint.query,
      data: data,
      error: error)
  }

  // MARK: Private

  private let networkLogTracker: NetworkLogTracker
}

// MARK: - Private

private extension ResponseMonitorInterceptorImp {
  func buildLogMessage(endpoint: some Endpoint,
                       response: HTTPURLResponse?,
                       requestParams: [String: AnyHashable],
                       data: Data?,
                       error: Error?)
  {
    let statusCodePart = response.map { "🔢 Status code: \($0.statusCode)" } ?? ""
    let headersPart = (response?.allHeaderFields as? [String: AnyObject]).map {
      "👤 Response Headers: \($0.prettyPrint(limit: 1000))"
    } ?? ""

    let paramsPart = !requestParams.isEmpty
      ? "📦 Params: \(requestParams.prettyPrint(limit: 1000))"
      : ""

    let responsePart = dataMessage(data)

    let errorPart = error.map {
      "⛔️ Error: \($0.asNetworkKitError?.description ?? "Unknown error")"
    } ?? ""

    let message = """

    ==================== Response Log ====================
    🎯 Endpoint: \(endpoint.url)
    ⚙️ Method: \(endpoint.method.rawValue)
    \(statusCodePart)
    \(headersPart)
    \(paramsPart)
    \(responsePart)
    \(errorPart)
    ======================================================
    """

    if error != nil {
      networkLogTracker.error("👉 ResilientNetworkKit", message)
    } else {
      networkLogTracker.infor("👉 ResilientNetworkKit", message)
    }
  }

  func dataMessage(_ data: Data?) -> String {
    guard let data else { return "" }

    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: AnyObject] {
      return "📦 Response: \(truncateString(json.prettyPrint(limit: 2000), limit: 2000))"
    } else if let rawString = String(data: data, encoding: .utf8) {
      return "📦 Response: \(truncateString(rawString, limit: 2000))"
    } else {
      return "📦 Response: [Unreadable Data]"
    }
  }

  func truncateString(_ string: String, limit: Int = 2000) -> String {
    guard string.count > limit else { return string }
    return String(string.prefix(limit)) + "\n... [truncated]"
  }
}

// MARK: - Pretty Print Dictionary Extension

private extension Dictionary where Key == String {
  func prettyPrint(limit: Int = 1000) -> String {
    let options: JSONSerialization.WritingOptions = [.prettyPrinted, .withoutEscapingSlashes]
    guard
      let data = try? JSONSerialization.data(withJSONObject: self, options: options),
      let str = String(data: data, encoding: .utf8) else
    {
      return "{invalid dictionary}"
    }

    if str.count > limit {
      return String(str.prefix(limit)) + "\n... [truncated]"
    }
    return str
  }
}
