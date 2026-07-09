//
//  RSMSLiveActivityLiveActivity.swift
//  RSMSLiveActivity
//
//  Created by Abhigyan Singh Jagwan on 09/07/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RSMSLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RSMSLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RSMSLiveActivityAttributes.self) { context in
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

extension RSMSLiveActivityAttributes {
    fileprivate static var preview: RSMSLiveActivityAttributes {
        RSMSLiveActivityAttributes(name: "World")
    }
}

extension RSMSLiveActivityAttributes.ContentState {
    fileprivate static var smiley: RSMSLiveActivityAttributes.ContentState {
        RSMSLiveActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RSMSLiveActivityAttributes.ContentState {
         RSMSLiveActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RSMSLiveActivityAttributes.preview) {
   RSMSLiveActivityLiveActivity()
} contentStates: {
    RSMSLiveActivityAttributes.ContentState.smiley
    RSMSLiveActivityAttributes.ContentState.starEyes
}
