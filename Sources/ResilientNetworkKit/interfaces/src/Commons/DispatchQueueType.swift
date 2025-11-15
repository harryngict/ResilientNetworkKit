import Foundation

// MARK: - DispatchQueueType

/// @mockable
public protocol DispatchQueueType: Sendable {
  func async(work: @Sendable @escaping () -> Void)
  func asyncAfter(deadline: DispatchTime, work: @Sendable @escaping () -> Void)
  func async(flags: DispatchWorkItemFlags, execute work: @escaping @Sendable @convention(block) () -> Void)
}

// MARK: - DispatchQueue + DispatchQueueType

extension DispatchQueue: DispatchQueueType {
  public func async(work: @Sendable @escaping () -> Void) {
    async(execute: work)
  }

  public func asyncAfter(deadline: DispatchTime, work: @Sendable @escaping () -> Void) {
    asyncAfter(deadline: deadline, execute: work)
  }

  public func async(flags: DispatchWorkItemFlags, execute work: @escaping @Sendable @convention(block) () -> Void) {
    async(group: nil, qos: .unspecified, flags: flags, execute: work)
  }
}
