import Foundation

// MARK: - NetworkLogTracker

/// @mockable
public protocol NetworkLogTracker: Sendable {
  func infor(_ tag: String, _ message: String)
  func warning(_ tag: String, _ message: String)
  func error(_ tag: String, _ message: String)
  func success(_ tag: String, _ message: String)
}

// MARK: - NetworkLogTrackerImp

open class NetworkLogTrackerImp: @unchecked Sendable, NetworkLogTracker {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public func infor(_ tag: String, _ message: String) {}
  public func warning(_ tag: String, _ message: String) {}
  public func error(_ tag: String, _ message: String) {}
  public func success(_ tag: String, _ message: String) {}
}
