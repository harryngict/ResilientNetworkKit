import Foundation
import ResilientNetworkKit

public struct RefreshTokenEndpoint: Endpoint, @unchecked Sendable {
  public typealias Response = AccountResponse

  public var query: [String: AnyHashable] = [:]
  public var headers: [String: String] = [:]

  public var isRefreshTokenEndpoint = true

  public var url: URL {
    URL(string: "https://jsonplaceholder.typicode.com/users/123")!
  }

  public var method: HTTPMethod {
    .get
  }
}
