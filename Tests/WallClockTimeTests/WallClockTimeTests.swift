import XCTest
@testable import WallClockTime

/// Every test pins the device zone explicitly, so the suite gives the same
/// result on a laptop in any zone and on CI (usually UTC).
final class WallClockTimeTests: XCTestCase {
    private var savedDefault: TimeZone!
    private let payload = EventPayload(startsAt: "2026-03-14T10:32:00Z")

    private func zone(_ id: String) -> TimeZone { TimeZone(identifier: id)! }

    override func setUp() {
        super.setUp()
        savedDefault = NSTimeZone.default
    }

    override func tearDown() {
        NSTimeZone.default = savedDefault
        super.tearDown()
    }

    // MARK: naive: documents the bug

    func test_naive_shows_10_32_only_when_device_is_in_UTC() {
        // Proves: the "Z" makes the parser read 10:32 as UTC, so only a UTC device looks right.
        XCTAssertEqual(NaiveEventFormatter.display(payload, deviceTimeZone: zone("UTC")),
                       "Mar 14, 2026 at 10:32 AM")
    }

    func test_naive_shifts_the_time_by_the_device_offset() {
        // Proves: the same payload renders differently per device zone (DST already active on Mar 14, 2026 in the US).
        let expected: [(String, String)] = [
            ("America/Chicago", "Mar 14, 2026 at 5:32 AM"),     // UTC-5
            ("America/Los_Angeles", "Mar 14, 2026 at 3:32 AM"), // UTC-7
            ("Europe/Berlin", "Mar 14, 2026 at 11:32 AM"),      // UTC+1
            ("Asia/Kolkata", "Mar 14, 2026 at 4:02 PM"),        // UTC+5:30
        ]
        for (id, text) in expected {
            XCTAssertEqual(NaiveEventFormatter.display(payload, deviceTimeZone: zone(id)), text, id)
        }
    }

    func test_naive_follows_NSTimeZone_default_when_no_zone_is_passed() {
        // Proves: the bug depends on ambient state, which is why a test on the venue's own machine can't see it.
        NSTimeZone.default = zone("America/Los_Angeles")
        XCTAssertEqual(NaiveEventFormatter.display(payload), "Mar 14, 2026 at 3:32 AM")
    }

    func test_naive_returns_empty_string_for_a_zoneless_iso_string() {
        // Proves: ISO8601DateFormatter's default options require a zone, so "...T10:32:00" fails to parse.
        XCTAssertEqual(NaiveEventFormatter.display(EventPayload(startsAt: "2026-03-14T10:32:00"),
                                                   deviceTimeZone: zone("UTC")), "")
    }

    func test_naive_composed_label_collapses_to_glue_characters() {
        // Proves: a failed parse inside a composed label leaves only the literal separators.
        XCTAssertEqual(NaiveEventFormatter.compactLabel("2026-03-14T10:32:00",
                                                        deviceTimeZone: zone("UTC")), "//, ")
    }

    func test_naive_fails_on_fractional_seconds_with_default_options() {
        // Proves: ".123Z" is rejected unless .withFractionalSeconds is set -- a second silent-empty trap.
        let date = ISO8601DateFormatter().date(from: "2026-03-14T10:32:00.123Z")
        XCTAssertNil(date)
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(f.date(from: "2026-03-14T10:32:00.123Z"))
    }

    // MARK: fixed: documents the expected behaviour

    func test_fixed_shows_10_32_whatever_the_zone_of_the_device() {
        // Proves: wall-clock rendering is zone independent; the same payload under 4 device zones gives one text.
        for id in ["UTC", "America/Chicago", "America/Los_Angeles", "Asia/Kolkata", "Pacific/Auckland"] {
            NSTimeZone.default = zone(id)
            XCTAssertEqual(FixedEventFormatter.display(payload), "Mar 14, 2026 at 10:32 AM", id)
        }
    }

    func test_fixed_prefers_the_server_preformatted_text_verbatim() {
        // Proves: when the payload carries a formatted string, it is shown untouched.
        let p = EventPayload(startsAt: "2026-03-14T10:32:00Z", startsAtDisplay: "Sat, Mar 14, 10:32 AM CDT")
        XCTAssertEqual(FixedEventFormatter.display(p), "Sat, Mar 14, 10:32 AM CDT")
    }

    func test_fixed_ignores_the_suffix_z_fraction_offset_or_nothing() {
        // Proves: every spelling of the same wall-clock value yields the same label.
        for s in ["2026-03-14T10:32:00Z", "2026-03-14T10:32:00", "2026-03-14T10:32:00.123Z",
                  "2026-03-14T10:32:00-05:00", "2026-03-14 10:32:00"] {
            XCTAssertEqual(FixedEventFormatter.compactLabel(s), "3/14/26, 10:32 AM", s)
        }
    }

    func test_fixed_composed_label_for_zoneless_string_is_not_glue() {
        // Proves: the zone-less string that broke the naive label now renders properly.
        XCTAssertEqual(FixedEventFormatter.compactLabel("2026-03-14T10:32:00"), "3/14/26, 10:32 AM")
    }

    func test_fixed_returns_empty_for_garbage_instead_of_wrong_time() {
        // Proves: invalid input yields an empty string, not a bogus time.
        XCTAssertEqual(FixedEventFormatter.display(EventPayload(startsAt: "tomorrow-ish")), "")
        XCTAssertNil(WallClock("2026-13-40T25:61:00Z"))
    }

    func test_fixed_formats_midnight_and_noon_correctly() {
        // Proves: the 12 AM / 12 PM edges survive the neutral container.
        XCTAssertEqual(WallClock("2026-03-14T00:05:00Z")?.formatted("h:mm a"), "12:05 AM")
        XCTAssertEqual(WallClock("2026-03-14T12:00:00Z")?.formatted("h:mm a"), "12:00 PM")
    }
}
