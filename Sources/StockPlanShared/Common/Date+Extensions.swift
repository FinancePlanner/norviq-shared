import Foundation

extension DateFormatter {
    public static let iso8601WithFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    } ()

    public static let iso8601Standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter
    } ()

    public static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    } ()
}

public enum SharedDateDecoder {
    public static func decodeDate<K: CodingKey>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Date {
        if let stringValue = try? container.decode(String.self, forKey: key) {
            if let parsed = ISO8601DateFormatter().date(from: stringValue) {
                return parsed
            }

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = fractionalFormatter.date(from: stringValue) {
                return parsed
            }

            if let parsed = DateFormatter.yyyyMMdd.date(from: stringValue) {
                return parsed
            }

            if let referenceSeconds = Double(stringValue) {
                return Date(timeIntervalSinceReferenceDate: referenceSeconds)
            }
        }

        if let referenceSeconds = try? container.decode(Double.self, forKey: key) {
            return Date(timeIntervalSinceReferenceDate: referenceSeconds)
        }

        if let referenceSeconds = try? container.decode(Int.self, forKey: key) {
            return Date(timeIntervalSinceReferenceDate: Double(referenceSeconds))
        }

        throw DecodingError.typeMismatch(
            Date.self,
            .init(
                codingPath: container.codingPath + [key],
                debugDescription: "Date must be an ISO8601 string or seconds since Apple reference date"
            )
        )
    }

    public static func decodeDate(from decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            if let parsed = ISO8601DateFormatter().date(from: stringValue) {
                return parsed
            }

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = fractionalFormatter.date(from: stringValue) {
                return parsed
            }

            if let parsed = DateFormatter.yyyyMMdd.date(from: stringValue) {
                return parsed
            }

            if let referenceSeconds = Double(stringValue) {
                return Date(timeIntervalSinceReferenceDate: referenceSeconds)
            }
        }

        if let referenceSeconds = try? container.decode(Double.self) {
            return Date(timeIntervalSinceReferenceDate: referenceSeconds)
        }

        if let referenceSeconds = try? container.decode(Int.self) {
            return Date(timeIntervalSinceReferenceDate: Double(referenceSeconds))
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Date must be an ISO8601 string or seconds since Apple reference date"
        )
    }
}

extension JSONDecoder {
    public static var stockPlanShared: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            try SharedDateDecoder.decodeDate(from: decoder)
        }
        return decoder
    }
}

extension JSONEncoder {
    public static var stockPlanShared: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

