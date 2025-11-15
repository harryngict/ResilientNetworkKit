import Foundation
import ResilientNetworkKit

open class ResponseErrorInspectorImp: @unchecked Sendable, ResponseErrorInspector {
  // MARK: Lifecycle

  public init() {}

  // MARK: Open

  open func inspect(_ data: Data?, endpoint: some Endpoint) -> Any {
    var payload: Any? = nil
    if let data {
      payload = try? JSONSerialization.jsonObject(with: data, options: [])
    }
    return payload ?? []
  }
}
