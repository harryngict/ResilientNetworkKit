import Combine
import Foundation
import ResilientNetworkKit

// MARK: - NetworkTraceInspectorImp

public final class NetworkTraceInspectorImp: @unchecked Sendable, NetworkTraceInspector {
  // MARK: Lifecycle

  private init() {}

  // MARK: Public

  // MARK: - BucketEvent

  @frozen
  public enum BucketEvent {
    case added(String)
    case updated(String)
    case cleared
  }

  public static let shared = NetworkTraceInspectorImp()

  public let records = DictionaryInThreadSafe<String, NetworkRequestWrapper>()

  public var eventPublisher: AnyPublisher<BucketEvent, Never> {
    eventSubject.eraseToAnyPublisher()
  }

  public func setup(networkLogTracker: NetworkLogTracker) {
    self.networkLogTracker = networkLogTracker
  }

  public func add(endpoint: some Endpoint,
                  startTime: TimeInterval,
                  endTime: TimeInterval?,
                  status: NetworkRequestStatus,
                  httpURLResponse: HTTPURLResponse?,
                  data: Data?,
                  error: ResilientNetworkKitError?)
  {
    let record = createItem(
      endpoint: endpoint,
      startTime: startTime,
      endTime: endTime,
      status: status,
      httpURLResponse: httpURLResponse,
      data: data,
      error: error)
    let id = getUniqueId(endpoint: endpoint, time: startTime)
    records[id] = NetworkRequestWrapper(record)
    eventSubject.send(.added(id))
  }

  public func update(endpoint: some Endpoint,
                     startTime: TimeInterval,
                     endTime: TimeInterval,
                     httpURLResponse: HTTPURLResponse? = nil,
                     data: Data? = nil,
                     error: ResilientNetworkKitError? = nil)
  {
    let id = getUniqueId(endpoint: endpoint, time: startTime)
    guard let currentItem = records[id] else {
      networkLogTracker?.warning(
        "NetworkTraceInspector",
        "Warning: Attempted to update a non-existing item for endpoint ID \(id).")
      add(
        endpoint: endpoint,
        startTime: startTime,
        endTime: endTime,
        status: .finished,
        httpURLResponse: httpURLResponse,
        data: data,
        error: error)
      return
    }

    let updatedRecord = createItem(
      endpoint: endpoint,
      startTime: currentItem.startTime,
      endTime: endTime,
      status: .finished,
      httpURLResponse: httpURLResponse,
      data: data,
      error: error)

    records[id] = NetworkRequestWrapper(updatedRecord)
    eventSubject.send(.updated(id))
  }

  public func clearAll() {
    records.removeAll()
    eventSubject.send(.cleared)
  }

  // MARK: Private

  private let eventSubject = PassthroughSubject<BucketEvent, Never>()
  private var networkLogTracker: NetworkLogTracker?

  private func createItem<E: Endpoint>(endpoint: E,
                                       startTime: TimeInterval,
                                       endTime: TimeInterval? = nil,
                                       status: NetworkRequestStatus,
                                       httpURLResponse: HTTPURLResponse? = nil,
                                       data: Data? = nil,
                                       error: ResilientNetworkKitError? = nil)
    -> NetworkRequestRecord<E>
  {
    NetworkRequestRecord(
      endpoint: endpoint,
      startTime: startTime,
      endTime: endTime,
      status: status,
      httpURLResponse: httpURLResponse,
      data: data,
      error: error)
  }

  private func getUniqueId(endpoint: any Endpoint, time: TimeInterval) -> String {
    "\(endpoint.id)_\(time)"
  }
}
