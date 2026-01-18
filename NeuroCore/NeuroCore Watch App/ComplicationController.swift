import ClockKit
import SwiftUI
import WidgetKit

// MARK: - Complication Data Provider

struct NeuroCoreComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NeuroCoreEntry {
        NeuroCoreEntry(date: Date(), streak: 0, recommendedMode: "Calm")
    }

    func getSnapshot(in context: Context, completion: @escaping (NeuroCoreEntry) -> Void) {
        let entry = NeuroCoreEntry(
            date: Date(),
            streak: UserDefaults.standard.integer(forKey: "neurocore.streak"),
            recommendedMode: getRecommendedModeName()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NeuroCoreEntry>) -> Void) {
        let currentDate = Date()
        let entry = NeuroCoreEntry(
            date: currentDate,
            streak: UserDefaults.standard.integer(forKey: "neurocore.streak"),
            recommendedMode: getRecommendedModeName()
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getRecommendedModeName() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9: return "Energy"
        case 9..<12: return "Focus"
        case 12..<14: return "Social"
        case 14..<18: return "Flow"
        case 18..<20: return "Unwind"
        case 20..<22: return "Calm"
        case 22..<24, 0..<5: return "Sleep"
        default: return "Calm"
        }
    }
}

// MARK: - Timeline Entry

struct NeuroCoreEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let recommendedMode: String
}

// MARK: - Complication Views

struct NeuroCoreCircularComplication: View {
    var entry: NeuroCoreEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)

                if entry.streak > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(entry.streak)")
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

struct NeuroCoreCornerComplication: View {
    var entry: NeuroCoreEntry

    var body: some View {
        ZStack {
            Image(systemName: "waveform.circle.fill")
                .font(.title)

            Text(entry.recommendedMode)
                .font(.caption2)
                .widgetCurvesContent()
        }
    }
}

struct NeuroCoreRectangularComplication: View {
    var entry: NeuroCoreEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue.gradient)

            VStack(alignment: .leading, spacing: 2) {
                Text("NeuroCore")
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text("Try \(entry.recommendedMode)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if entry.streak > 0 {
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(entry.streak)")
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

struct NeuroCoreInlineComplication: View {
    var entry: NeuroCoreEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
            Text("NeuroCore: \(entry.recommendedMode)")
        }
    }
}

// MARK: - Complication View Router

struct NeuroCoreComplicationView: View {
    var entry: NeuroCoreEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            NeuroCoreCircularComplication(entry: entry)
        case .accessoryCorner:
            NeuroCoreCornerComplication(entry: entry)
        case .accessoryRectangular:
            NeuroCoreRectangularComplication(entry: entry)
        case .accessoryInline:
            NeuroCoreInlineComplication(entry: entry)
        default:
            NeuroCoreCircularComplication(entry: entry)
        }
    }
}

// MARK: - Widget Definition
// Note: To use complications, add a Widget Extension target to your Xcode project
// and use the following widget configuration:

/*
 @main
 struct NeuroCoreWidget: Widget {
     let kind: String = "NeuroCoreComplication"

     var body: some WidgetConfiguration {
         StaticConfiguration(kind: kind, provider: NeuroCoreComplicationProvider()) { entry in
             NeuroCoreComplicationView(entry: entry)
         }
         .configurationDisplayName("NeuroCore")
         .description("Quick access to haptic wellness")
         .supportedFamilies([
             .accessoryCircular,
             .accessoryCorner,
             .accessoryRectangular,
             .accessoryInline
         ])
     }
 }
 */

// MARK: - Complication Refresh Helper

class ComplicationRefreshManager {
    static let shared = ComplicationRefreshManager()

    func refreshComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "NeuroCoreComplication")
    }

    func refreshAfterSession() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.refreshComplications()
        }
    }
}
