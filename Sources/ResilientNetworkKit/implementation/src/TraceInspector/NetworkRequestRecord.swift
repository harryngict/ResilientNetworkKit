import Foundation
import ResilientNetworkKit

// MARK: - NetworkRequestRecord

public struct NetworkRequestRecord<E: Endpoint> {
  // MARK: Lifecycle

  public init(endpoint: E,
              startTime: TimeInterval,
              endTime: TimeInterval? = nil,
              status: NetworkRequestStatus,
              httpURLResponse: HTTPURLResponse? = nil,
              data: Data? = nil,
              error: ResilientNetworkKitError? = nil)
  {
    self.endpoint = endpoint
    self.startTime = startTime
    self.endTime = endTime
    self.status = status
    self.httpURLResponse = httpURLResponse
    self.data = data
    self.error = error
  }

  // MARK: Public

  public let endpoint: E
  public let startTime: TimeInterval
  public var endTime: TimeInterval?
  public var status: NetworkRequestStatus
  public var httpURLResponse: HTTPURLResponse?
  public var data: Data?
  public var error: ResilientNetworkKitError?
}
