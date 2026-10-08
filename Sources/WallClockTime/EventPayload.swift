import Foundation

/// What the backend sends for an event at a venue.
///
/// `startsAt` is the venue's wall-clock time, but the serializer stamped a
/// literal `Z` on it. It is NOT a UTC instant.
public struct EventPayload: Equatable, Sendable {
    /// e.g. "2026-03-14T10:32:00Z" (really: 10:32 at the venue)
    public let startsAt: String
    /// Optional, already formatted and correctly localized by the server.
    public let startsAtDisplay: String?

    public init(startsAt: String, startsAtDisplay: String? = nil) {
        self.startsAt = startsAt
        self.startsAtDisplay = startsAtDisplay
    }
}
