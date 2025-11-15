import Foundation
import ResilientNetworkKit

// MARK: - NetworkRequestWrapper

public struct NetworkRequestWrapper: @unchecked Sendable {
  // MARK: Lifecycle

  public init(_ item: NetworkRequestRecord<some Endpoint>) {
    startTime = item.startTime
    endTime = item.endTime
    status = item.status
    endpoint = item.endpoint
    httpURLResponse = item.httpURLResponse
    data = item.data
    error = item.error
  }

  // MARK: Public

  public let endpoint: any Endpoint
  public let startTime: TimeInterval
  public var endTime: TimeInterval?
  public let status: NetworkRequestStatus
  public var httpURLResponse: HTTPURLResponse?
  public var data: Data?
  public var error: ResilientNetworkKitError?

  public func getStatusCode() -> Int? {
    if let error {
      return error.statusCode
    }
    return httpURLResponse?.statusCode
  }

  public func getResponseString(endpoint: some Endpoint) -> String? {
    guard let responseData = data else { return nil }
    do {
      let result: String = try endpoint.responseParser.parse(data: responseData)
      return result
    } catch {
      return nil
    }
  }
}
