import Foundation
import ResilientNetworkKit

// MARK: - AccountEndpoint

public struct AccountEndpoint: Endpoint, @unchecked Sendable {
  public typealias Response = [AccountResponse]

  public var query: [String: AnyHashable] = [:]
  public var headers: [String: String] = [:]

  public var url: URL {
    URL(string: "https://jsonplaceholder.typicode.com/users")!
  }

  public var method: HTTPMethod {
    .get
  }
}
