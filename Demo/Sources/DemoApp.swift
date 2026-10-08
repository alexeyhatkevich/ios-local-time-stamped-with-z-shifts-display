import SwiftUI
import WallClockTime

@main
struct DemoApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    private let zones = ["America/Chicago", "America/Los_Angeles", "Europe/Berlin", "Asia/Kolkata"]
    @State private var zoneID = "America/Chicago"
    @State private var useServerText = false

    private var payload: EventPayload {
        EventPayload(startsAt: "2026-03-14T10:32:00Z",
                     startsAtDisplay: useServerText ? "Mar 14, 2026 at 10:32 AM" : nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event at the venue: 10:32 AM (venue wall clock)").font(.headline)
            Text("Backend field: \"2026-03-14T10:32:00Z\"  (the Z is wrong)")
                .font(.footnote).foregroundStyle(.secondary)
            Text("Pretend the phone is in:")
            Picker("Device zone", selection: $zoneID) {
                ForEach(zones, id: \.self) { Text($0.split(separator: "/").last!) .tag($0) }
            }.pickerStyle(.segmented)
            Toggle("Fixed uses server-formatted text", isOn: $useServerText)

            row("Naive (parse as instant)",
                NaiveEventFormatter.display(payload, deviceTimeZone: TimeZone(identifier: zoneID)!), .red)
            row("Fixed (wall clock)", FixedEventFormatter.display(payload), .green)

            Divider()
            Text("Zone-less string 2026-03-14T10:32:00").font(.subheadline)
            row("Naive label", NaiveEventFormatter.compactLabel("2026-03-14T10:32:00"), .red)
            row("Fixed label", FixedEventFormatter.compactLabel("2026-03-14T10:32:00"), .green)

            Text("Look for: Naive changes when you switch the zone, Fixed never does.")
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }.padding()
    }

    private func row(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.isEmpty ? "(empty)" : value).font(.title3.monospaced()).foregroundStyle(color)
        }
    }
}
