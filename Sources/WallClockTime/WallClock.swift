import Foundation

/// A calendar date plus a time of day with NO time zone. This is deliberately
/// not a `Date`: a `Date` is an instant, a wall-clock time is not.
public struct WallClock: Equatable, Sendable {
    public let year, month, day, hour, minute, second: Int

    /// Parses `yyyy-MM-ddTHH:mm:ss` and ignores whatever follows (`Z`, `.123Z`,
    /// `+02:00`, nothing). The contract says the value is venue-local, so any
    /// suffix is noise and must not move the time.
    public init?(_ iso: String) {
        let chars = Array(iso.utf8)
        guard chars.count >= 19 else { return nil }
        func num(_ range: Range<Int>) -> Int? {
            var value = 0
            for i in range {
                let c = chars[i]
                guard c >= 48, c <= 57 else { return nil }
                value = value * 10 + Int(c - 48)
            }
            return value
        }
        guard chars[4] == 45, chars[7] == 45, chars[10] == 84 || chars[10] == 32,
              chars[13] == 58, chars[16] == 58,
              let y = num(0..<4), let mo = num(5..<7), let d = num(8..<10),
              let h = num(11..<13), let mi = num(14..<16), let s = num(17..<19),
              (1...12).contains(mo), (1...31).contains(d),
              h < 24, mi < 60, s < 60
        else { return nil }
        (year, month, day, hour, minute, second) = (y, mo, d, h, mi, s)
    }

    /// Formats the components as they are. Uses a fixed UTC calendar only as a
    /// neutral container; no device-zone conversion can happen.
    public func formatted(_ pattern: String = "MMM d, yyyy 'at' h:mm a",
                          locale: Locale = Locale(identifier: "en_US")) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = DateComponents(calendar: cal, timeZone: cal.timeZone, year: year, month: month,
                                   day: day, hour: hour, minute: minute, second: second)
        guard let container = cal.date(from: comps) else { return "" }
        let f = DateFormatter()
        f.locale = locale
        f.calendar = cal
        f.timeZone = cal.timeZone
        f.dateFormat = pattern
        return f.string(from: container)
    }
}
