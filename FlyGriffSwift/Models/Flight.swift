import Foundation

struct Flight: Identifiable, Decodable {
    let raw: [String: JSONValue]

    var id: String {
        if let value = stringValue(for: ["flight_id", "id"]) {
            return value
        }
        return UUID().uuidString
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decode([String: JSONValue].self)
    }

    func stringValue(for keys: [String]) -> String? {
        for key in keys {
            guard let value = raw[key] else { continue }
            switch value {
            case .string(let string):
                if !string.isEmpty { return string }
            case .number(let number):
                return String(number)
            case .bool(let bool):
                return String(bool)
            case .null, .array, .object:
                continue
            }
        }
        return nil
    }

    func doubleValue(for keys: [String]) -> Double? {
        for key in keys {
            guard let value = raw[key] else { continue }
            switch value {
            case .number(let number):
                return number
            case .string(let string):
                if let parsed = Double(string) { return parsed }
            default:
                continue
            }
        }
        return nil
    }
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
}