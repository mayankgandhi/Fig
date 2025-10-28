/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The metadata structure for the activity attribues shared between the app and the widget extension.
*/

import AlarmKit

struct TickerData: AlarmMetadata, Codable, Hashable {
    let createdAt: Date
    let name: String?
    let icon: String?
    let colorHex: String?

    init(name: String? = nil, icon: String? = nil, colorHex: String? = nil) {
        self.createdAt = Date.now
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
