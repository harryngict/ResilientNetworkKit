
import Foundation

// MARK: - AccountResponse

public struct AccountResponse: Decodable {
  public let id: Int
  public let name: String
  public let username: String
  public let email: String
}
