import Foundation
import ResilientNetworkKit
import ResilientNetworkKitImp

final class ClientResponseMonitorInterceptorImp: ResponseMonitorInterceptorImp, @unchecked Sendable {
  // MARK: Lifecycle

  override init(networkLogTracker: NetworkLogTracker) {
    super.init(networkLogTracker: networkLogTracker)
  }

  // MARK: Internal

  override func monitorResponse(endpoint: some Endpoint,
                                response: HTTPURLResponse?,
                                error: Error?,
                                data: Data?,
                                requestStartTime: TimeInterval,
                                requestEndTime: TimeInterval)
  {
    super.monitorResponse(
      endpoint: endpoint,
      response: response,
      error: error,
      data: data,
      requestStartTime: requestStartTime,
      requestEndTime: requestEndTime)
  }
}
