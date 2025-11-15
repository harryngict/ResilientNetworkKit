import Foundation

public enum StatusCode: Equatable, Sendable {
  case success(Int)
  case badRequest
  case unauthorised
  case forbidden
  case methodNotAllowed
  case timeout
  case conflict
  case tooManyRequests
  case otherClientError(Int)
  case serverError(Int)
  case unknown(Int)

  // MARK: Lifecycle

  public init(code: Int) {
    switch code {
    case 200 ... 299: self = .success(code)
    case 400: self = .badRequest
    case 401: self = .unauthorised
    case 403: self = .forbidden
    case 405: self = .methodNotAllowed
    case 408: self = .timeout
    case 409: self = .conflict
    case 429: self = .tooManyRequests
    case 400 ... 499: self = .otherClientError(code)
    case 500 ... 599: self = .serverError(code)
    default: self = .unknown(code)
    }
  }

  // MARK: Public

  public var code: Int {
    switch self {
    case .badRequest: return 400
    case .unauthorised: return 401
    case .forbidden: return 403
    case .methodNotAllowed: return 405
    case .timeout: return 408
    case .conflict: return 409
    case .tooManyRequests: return 429
    case let .otherClientError(code),
         let .serverError(code),
         let .success(code),
         let .unknown(code): return code
    }
  }
}
