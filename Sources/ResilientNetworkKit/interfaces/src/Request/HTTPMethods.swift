import Foundation

@frozen
public enum HTTPMethod: String, Encodable, Equatable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case head = "HEAD"
  case patch = "PATCH"
}
