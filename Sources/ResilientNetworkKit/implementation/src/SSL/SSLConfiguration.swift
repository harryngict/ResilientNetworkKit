import Foundation

public struct SSLConfiguration {
  // MARK: Lifecycle

  public init(isPinningEnabled: Bool,
              pinnedHostIdentities: [SSLHostIdentity])
  {
    self.isPinningEnabled = isPinningEnabled
    self.pinnedHostIdentities = pinnedHostIdentities
  }

  // MARK: Internal

  let isPinningEnabled: Bool
  let pinnedHostIdentities: [SSLHostIdentity]
}
