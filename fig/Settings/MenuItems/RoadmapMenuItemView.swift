import SwiftUI
import TickerCore

struct RoadmapMenuItemView: View {
    @State private var showRoadmap = false

    var body: some View {
        NativeMenuListItem(
            icon: "list.bullet.rectangle",
            title: "Roadmap & Feature Requests",
            subtitle: "Request or upvote features",
            iconColor: TickerColor.accent
        ) {
            showRoadmap = true
        }
        .sheet(isPresented: $showRoadmap) {
            NavigationStack {
                RoadmapScreen()
            }
            .presentationDetents([.large])
            .presentationCornerRadius(TickerRadius.large)
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    RoadmapMenuItemView()
}


