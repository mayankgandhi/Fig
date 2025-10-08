//
//  ConfigurationAppIntent.swift
//  fig
//
//  Widget configuration intent
//

import WidgetKit
import AppIntents

/// A configuration intent for the alarm widget
///
/// This intent allows users to configure the widget with a custom emoji.
/// It's used by the `AppIntentConfiguration` to provide configurable parameters
/// for the widget.
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    /// The user's favorite emoji to display in the widget
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
