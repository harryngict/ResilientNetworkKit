import Foundation

public extension Data {
  func toJSONString(encoding: String.Encoding = .utf8) -> String? {
    guard
      let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
      let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
      let jsonString = String(data: data, encoding: encoding) else
    {
      return nil
    }
    return jsonString
  }

  func toDictionary() -> [String: Any]? {
    try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
  }

  func to<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? {
    try? decoder.decode(type.self, from: self)
  }
}
