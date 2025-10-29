/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The metadata structure for the activity attribues shared between the app and the widget extension.
*/

import AlarmKit

public struct TickerData: AlarmMetadata, Codable, Hashable {
    public let createdAt: Date
    public let name: String?
    public let icon: String?
    public let colorHex: String?

    public init(name: String? = nil, icon: String? = nil, colorHex: String? = nil) {
        self.createdAt = Date.now
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
