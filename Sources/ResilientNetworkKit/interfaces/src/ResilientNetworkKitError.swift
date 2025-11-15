import Foundation

// MARK: - ResilientNetworkKitError

public enum ResilientNetworkKitError: Error, @unchecked Sendable {
  /// An unknown error, typically used when no specific error can be classified.
  /// - Parameter error: The underlying error that caused the issue, if available.
  case unknown(error: Error?)

  /// A general network-related error, such as a failed connection or timeout.
  /// - Parameter error: The underlying error that occurred during the network operation.
  case networkError(error: Error?)

  /// A client-side error, where the problem is related to the client's request or action.
  /// Example: Invalid parameters or unauthorized access.
  /// - Parameter error: The client-side error details, encapsulated in a `ClientError` object.
  case clientError(error: ClientError)

  /// A conflict error, where the server response indicates a conflict with the request data.
  /// Example: HTTP 409 status, indicating the resource already exists or there is a conflict with existing data.
  /// - Parameter data: The conflict data returned by the server, usually in a dictionary format.
  case conflict(data: [String: Any])

  /// A server-side error, where the server responded with an error (e.g., HTTP 500).
  /// - Parameter response: The `HTTPURLResponse` object containing the server's response.
  /// - Parameter error: An optional error from the server, if any.
  /// - Parameter data: Any additional data returned with the response (such as error details).
  case serverError(response: HTTPURLResponse, error: Error?, data: Data?)

  /// A failure that occurs when trying to cast the HTTP response to the expected type.
  /// This happens when the response format does not match the expected type.
  case httpResponseTypeCastFailed

  /// An error where the expected data was found to be nil.
  /// This could happen if a required resource or payload is missing from the server's response.
  case dataFoundNil

  /// An error where the network request was canceled, either by the user or the app.
  /// Example: User cancels the request or navigates away before the request completes.
  case canceled

  /// An error that occurred while encoding the request body (e.g., when converting an object to JSON).
  /// - Parameter error: The error that occurred during the encoding process.
  case encodeBodyFailed(error: Error)

  /// A failure to decode the response data into the expected type.
  /// This may occur if the data received from the server cannot be converted into a model object.
  /// - Parameter type: The type that was expected to be decoded from the response data.
  /// - Parameter error: The underlying error that occurred during decoding.
  case decodingFailed(type: Any.Type, error: Error)

  /// An invalid URL error, typically when the URL is malformed or cannot be constructed.
  /// - Parameter url: The URL string that failed to be properly formed or used.
  case invalidURL(url: String?)

  /// An error triggered by a circuit breaker being open.
  /// This typically occurs after multiple consecutive failures, where further requests are paused to avoid overloading the system.
  case circuitBreakerOpen

  /// An error returned by the API with a 200 OK status, but with a response code and message indicating an error or unusual condition.
  /// - Parameter responseCode: The response code that indicates an error condition (if any).
  /// - Parameter message: The message describing the error or unusual condition.
  case customError(responseCode: Int?, message: String?)

  // MARK: Public

  public var statusCode: Int? {
    switch self {
    case let .serverError(response, _, _):
      return response.statusCode
    case let .clientError(error):
      return error.statusCode.code
    case let .customError(responseCode, _):
      return responseCode
    default:
      return nil
    }
  }
}

// MARK: Equatable

extension ResilientNetworkKitError: Equatable {
  public static func == (lhs: ResilientNetworkKitError, rhs: ResilientNetworkKitError) -> Bool {
    switch (lhs, rhs) {
    case let (.conflict(lhsData), .conflict(rhsData)):
      return NSDictionary(dictionary: lhsData).isEqual(to: rhsData)
    default:
      return lhs.statusCode == rhs.statusCode
    }
  }
}

// MARK: CustomStringConvertible

extension ResilientNetworkKitError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .unknown(error):
      return "Unknown error: \(error?.localizedDescription ?? "No additional information")"
    case let .networkError(error):
      return "Network error occurred: \(error?.localizedDescription ?? "No additional information")"
    case let .serverError(response, error, data):
      return "Server error: HTTP \(response.statusCode) - \(data?.toJSONString() ?? error?.localizedDescription ?? "")"
    case let .clientError(error):
      return "Client error: HTTP \(error.statusCode.code) - \(error.userInfo)"
    case let .conflict(data):
      return "Conflict error: \(data)"
    case .httpResponseTypeCastFailed:
      return "Failed to cast HTTP response to the expected type"
    case .dataFoundNil:
      return "Data unexpectedly found nil"
    case .canceled:
      return "Request was canceled"
    case let .encodeBodyFailed(error):
      return "Failed to encode the request body: \(error.localizedDescription)"
    case let .decodingFailed(type, error):
      return """
      Error: \(error.localizedDescription).
      Decoding failed for type '\(type)'.
      """
    case let .invalidURL(url):
      return "Invalid URL provided: \(url ?? "No URL")"
    case .circuitBreakerOpen:
      return "Circuit breaker is open, rejecting the request"
    case let .customError(_, message):
      return message ?? "No message provided"
    }
  }
}

// MARK: ResilientNetworkKitError.ClientError

public extension ResilientNetworkKitError {
  struct ClientError: Equatable, @unchecked Sendable {
    // MARK: Lifecycle

    public init(statusCode: StatusCode,
                allHeaderFields: [AnyHashable: Any],
                userInfo: [String: Any])
    {
      self.statusCode = statusCode
      self.allHeaderFields = allHeaderFields
      self.userInfo = userInfo
      decodedResponseData = userInfo["decodedResponse"] as Any
    }

    // MARK: Public

    public let statusCode: StatusCode
    public let allHeaderFields: [AnyHashable: Any]
    public let userInfo: [String: Any]
    public let decodedResponseData: Any

    public static func == (lhs: ResilientNetworkKitError.ClientError, rhs: ResilientNetworkKitError.ClientError) -> Bool {
      lhs.statusCode == rhs.statusCode && lhs.userInfo.keys == rhs.userInfo.keys
    }
  }
}

// MARK: - Transformations

public extension Error {
  var asNetworkKitError: ResilientNetworkKitError? {
    self as? ResilientNetworkKitError
  }
}
