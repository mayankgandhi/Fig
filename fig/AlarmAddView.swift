/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view for adding and configuring a new alarm.
*/

import SwiftUI
import WalnutDesignSystem

struct AlarmAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmService.self) private var alarmService

    var body: some View {
        AlarmEditorView(alarmService: alarmService)
    }
}
