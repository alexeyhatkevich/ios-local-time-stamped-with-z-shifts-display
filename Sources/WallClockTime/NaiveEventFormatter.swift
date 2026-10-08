import Foundation

/// THE BUG: treats the string as an instant and renders it in the device zone.
public enum NaiveEventFormatter {
    /// "Mar 14, 2026 at 10:32 AM" -- but shifted by the device offset.
    public static func display(_ payload: EventPayload,
                               deviceTimeZone: TimeZone = NSTimeZone.default) -> String {
        guard let date = ISO8601DateFormatter().date(from: payload.startsAt) else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.timeZone = deviceTimeZone
        f.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return f.string(from: date)
    }

    /// Composed label "3/14/26, 10:32 AM". With a zone-less string the strict
    /// ISO8601 parser returns nil, every part becomes "" and the label is "//, ".
    public static func compactLabel(_ isoString: String,
                                    deviceTimeZone: TimeZone = NSTimeZone.default) -> String {
        let date = ISO8601DateFormatter().date(from: isoString)
        func part(_ pattern: String) -> String {
            guard let date else { return "" }
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US")
            f.timeZone = deviceTimeZone
            f.dateFormat = pattern
            return f.string(from: date)
        }
        return "\(part("M"))/\(part("d"))/\(part("yy")), \(part("h:mm a"))"
    }
}
