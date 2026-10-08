# A "Z" timestamp that is really local time shifts the displayed time

A backend sends `2026-03-14T10:32:00Z` for an event at a venue. The `Z` was stamped on the venue's wall-clock time by a sloppy serializer, so the value is *not* a UTC instant. An iOS client that parses it as an instant and renders it in the device time zone shows 10:32 AM as 5:32 AM on a phone in Chicago, 3:32 AM in Los Angeles, 4:02 PM in Mumbai. Tests written on a machine in the venue's own zone never notice.

A related trap: a zone-less string (`2026-03-14T10:32:00`) fed to `ISO8601DateFormatter` with its default options returns `nil`, and a label composed from optional parts renders as literal glue: `//, `.

## How to run

1. Open `Demo/Demo.xcodeproj` in Xcode 15+ (or `xed Demo`), pick an iPhone simulator, press Cmd-R. Switch the "Pretend the phone is in" control: the red Naive line changes with the zone, the green Fixed line stays at 10:32 AM. The lower block shows the zone-less string: Naive prints `//, `, Fixed prints a proper label.
2. Tests: Cmd-U in the same project, or from the terminal:
   `swift test`
   (pure Foundation, no simulator needed).
3. Alternatively open `Package.swift` directly for just the library and tests.

## The fix

1. Best: have the server emit a fixed-zone, pre-formatted string and display it verbatim (`EventPayload.startsAtDisplay`).
2. Client side, when the contract says "venue-local": treat the value as a wall-clock time (`WallClock`), never as a `Date`. Parse the components, ignore any `Z` / fraction / offset suffix, and format them without any device-zone conversion.
3. Pin tests to explicit zones (`TimeZone(identifier:)`, save and restore `NSTimeZone.default` in `setUp` / `tearDown`) and run the same payload under several zones.

A `Date` is an instant. A wall-clock time is not a `Date`.

## Layout

- `Sources/WallClockTime/NaiveEventFormatter.swift` - the bug
- `Sources/WallClockTime/WallClock.swift`, `FixedEventFormatter.swift` - the fix
- `Tests/WallClockTimeTests` - `test_naive_*` documents the bug, `test_fixed_*` pins the fix
- `Demo/` - SwiftUI app (XcodeGen spec committed, generated project committed)

Write-up: https://alexeyhatkevich.blogspot.com
