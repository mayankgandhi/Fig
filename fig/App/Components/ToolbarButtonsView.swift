//
//  ToolbarButtonsView.swift
//  fig
//
//  Toolbar buttons component for ContentView
//

import SwiftUI

struct ToolbarButtonsView: View {
    
    @Binding var showAddSheet: Bool
    @Binding var showNaturalLanguageSheet: Bool
    var namespace: Namespace.ID
    
    var body: some View {
        ToolbarItemGroup(placement: .primaryAction) {
            plusButton
            
            if #available(iOS 26.0, *), DeviceCapabilities.supportsAppleIntelligence {
                aiButton
            }
        }
    }
    
    // MARK: - Private Views
    
    private var plusButton: some View {
        Button {
            TickerHaptics.selection()
            showAddSheet.toggle()
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
                    namespace: Namespace().wrappedValue
                )
            }
    }
}
