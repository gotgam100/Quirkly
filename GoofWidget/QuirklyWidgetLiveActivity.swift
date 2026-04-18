//
//  QuirklyWidgetLiveActivity.swift
//  QuirklyWidget
//
//  Created by BAEKMAC on 4/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct QuirklyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct QuirklyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuirklyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension QuirklyWidgetAttributes {
    fileprivate static var preview: QuirklyWidgetAttributes {
        QuirklyWidgetAttributes(name: "World")
    }
}

extension QuirklyWidgetAttributes.ContentState {
    fileprivate static var smiley: QuirklyWidgetAttributes.ContentState {
        QuirklyWidgetAttributes.ContentState(emoji: "😀")
     }

     fileprivate static var starEyes: QuirklyWidgetAttributes.ContentState {
         QuirklyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: QuirklyWidgetAttributes.preview) {
   QuirklyWidgetLiveActivity()
} contentStates: {
    QuirklyWidgetAttributes.ContentState.smiley
    QuirklyWidgetAttributes.ContentState.starEyes
}
