import Foundation

/// THE FIX: prefer the server's pre-formatted text; otherwise treat the string
/// as a wall-clock time and never convert it.
public enum FixedEventFormatter {
    public static func display(_ payload: EventPayload) -> String {
        if let text = payload.startsAtDisplay, !text.isEmpty { return text }
        return WallClock(payload.startsAt)?.formatted() ?? ""
    }

    /// "3/14/26, 10:32 AM". Works with or without a zone suffix.
    public static func compactLabel(_ isoString: String) -> String {
        guard let wc = WallClock(isoString) else { return "" }
        return "\(wc.formatted("M"))/\(wc.formatted("d"))/\(wc.formatted("yy")), \(wc.formatted("h:mm a"))"
    }
}
