//
//  GoofWidgetLiveActivity.swift
//  GoofWidget
//
//  Created by BAEKMAC on 4/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GoofWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GoofWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoofWidgetAttributes.self) { context in
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

extension GoofWidgetAttributes {
    fileprivate static var preview: GoofWidgetAttributes {
        GoofWidgetAttributes(name: "World")
    }
}

extension GoofWidgetAttributes.ContentState {
    fileprivate static var smiley: GoofWidgetAttributes.ContentState {
        GoofWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GoofWidgetAttributes.ContentState {
         GoofWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GoofWidgetAttributes.preview) {
   GoofWidgetLiveActivity()
} contentStates: {
    GoofWidgetAttributes.ContentState.smiley
    GoofWidgetAttributes.ContentState.starEyes
}
