import Foundation

extension Date {
  var millisecondsSince1970: TimeInterval {
    (timeIntervalSince1970 * 1000).rounded()
  }
}
