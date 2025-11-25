//
//  ToolbarButtonsView.swift
//  fig
//
//  Toolbar buttons component for ContentView
//

import SwiftUI
import TickerCore

struct ToolbarButtonsView: View {

    @Binding var showAddSheet: Bool
    @Binding var showNaturalLanguageSheet: Bool
    @Binding var showAddSleepScheduleSheet: Bool
    var namespace: Namespace.ID

    var body: some View {
        Group {
            plusButton
            aiButton
        }
    }

    // MARK: - Private Views

    private var plusButton: some View {
        Menu {
            Button {
                TickerHaptics.selection()
                showAddSheet = true
            } label: {
                Label("Standard Alarm", systemImage: "alarm")
            }

            Button {
                TickerHaptics.selection()
                showAddSleepScheduleSheet = true
            } label: {
                Label("Sleep Schedule", systemImage: "bed.double.fill")
            }
        } label: {
            Image(systemName: "plus")
        }
        .matchedTransitionSource(id: "addButton", in: namespace)
    }
    
    @available(iOS 26.0, *)
    private var aiButton: some View {
        Button {
            TickerHaptics.selection()
            showNaturalLanguageSheet.toggle()
        } label: {
            Image(systemName: "apple.intelligence")
        }
    }
}

#Preview {
    NavigationStack {
        Text("Preview")
            .toolbar {
                ToolbarButtonsView(
                    showAddSheet: .constant(false),
                    showNaturalLanguageSheet: .constant(false),
                    showAddSleepScheduleSheet: .constant(false),
                    namespace: Namespace().wrappedValue
                )
            }
    }
}
