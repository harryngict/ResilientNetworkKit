import ResilientNetworkKit

// MARK: - AppDependency

protocol AppDependency: AnyObject {
  var networkKit: ResilientNetworkKit { get }
}

// MARK: - AppDependencyImp

final class AppDependencyImp: AppDependency {
  // MARK: Lifecycle

  init(networkKit: ResilientNetworkKit) {
    self.networkKit = networkKit
  }

  // MARK: Internal

  let networkKit: ResilientNetworkKit
}
