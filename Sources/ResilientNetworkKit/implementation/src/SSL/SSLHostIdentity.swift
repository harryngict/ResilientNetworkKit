import Foundation

// MARK: - SSLHostIdentity

public protocol SSLHostIdentity {
  var host: String { get }
  var inUseKeys: Set<String> { get }
  var backupKeys: Set<String> { get }
  func keys() -> Set<String>
}

// MARK: - Default Implementation

public extension SSLHostIdentity {
  func keys() -> Set<String> {
    inUseKeys.union(backupKeys)
  }
}
