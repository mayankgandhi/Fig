//
//  Font+SFProRounded.swift
//  fig
//
//  SF Pro Rounded font extension for consistent typography
//  Provides view modifiers for all Dynamic Type styles
//

import SwiftUI

extension Font {


    // MARK: - Dynamic Type Styles with SF Pro Rounded

    /// Large Title style with SF Pro Rounded (34pt base, scales with Dynamic Type)
    static var cabinetLargeTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }

    /// Title 1 style with SF Pro Rounded (28pt base, scales with Dynamic Type)
    static var cabinetTitle: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    /// Title 2 style with SF Pro Rounded (22pt base, scales with Dynamic Type)
    static var cabinetTitle2: Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }

    /// Title 3 style with SF Pro Rounded (20pt base, scales with Dynamic Type)
    static var cabinetTitle3: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    /// Headline style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var cabinetHeadline: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    /// Body style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var cabinetBody: Font {
        .system(size: 17, weight: .regular, design: .rounded)
    }

    /// Callout style with SF Pro Rounded (16pt base, scales with Dynamic Type)
    static var cabinetCallout: Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    /// Subheadline style with SF Pro Rounded (15pt base, scales with Dynamic Type)
    static var cabinetSubheadline: Font {
        .system(size: 15, weight: .semibold, design: .rounded)
    }

    /// Footnote style with SF Pro Rounded (13pt base, scales with Dynamic Type)
    static var cabinetFootnote: Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }

    /// Caption 1 style with SF Pro Rounded (12pt base, scales with Dynamic Type)
    static var cabinetCaption: Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }

    /// Caption 2 style with SF Pro Rounded (11pt base, scales with Dynamic Type)
    static var cabinetCaption2: Font {
        .system(size: 11, weight: .regular, design: .rounded)
    }


}

// MARK: - View Extension for Easy Application

extension View {

    /// Apply SF Pro Rounded large title style
    func cabinetLargeTitle() -> some View {
        self.font(.cabinetLargeTitle)
    }

    /// Apply SF Pro Rounded title style
    func cabinetTitle() -> some View {
        self.font(.cabinetTitle)
    }

    /// Apply SF Pro Rounded title 2 style
    func cabinetTitle2() -> some View {
        self.font(.cabinetTitle2)
    }

    /// Apply SF Pro Rounded title 3 style
    func cabinetTitle3() -> some View {
        self.font(.cabinetTitle3)
    }

    /// Apply SF Pro Rounded headline style
    func cabinetHeadline() -> some View {
        self.font(.cabinetHeadline)
    }

    /// Apply SF Pro Rounded body style
    func cabinetBody() -> some View {
        self.font(.cabinetBody)
    }

    /// Apply SF Pro Rounded callout style
    func cabinetCallout() -> some View {
        self.font(.cabinetCallout)
    }

    /// Apply SF Pro Rounded subheadline style
    func cabinetSubheadline() -> some View {
        self.font(.cabinetSubheadline)
    }

    /// Apply SF Pro Rounded footnote style
    func cabinetFootnote() -> some View {
        self.font(.cabinetFootnote)
    }

    /// Apply SF Pro Rounded caption style
    func cabinetCaption() -> some View {
        self.font(.cabinetCaption)
    }

    /// Apply SF Pro Rounded caption 2 style
    func cabinetCaption2() -> some View {
        self.font(.cabinetCaption2)
    }

}

// MARK: - Preview Helper

#Preview("SF Pro Rounded Font Styles") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Large Title")
                    .cabinetLargeTitle()

                Text("Title")
                    .cabinetTitle()

                Text("Title 2")
                    .cabinetTitle2()

                Text("Title 3")
                    .cabinetTitle3()

                Text("Headline")
                    .cabinetHeadline()
            }

            Group {
                Text("Body Text - Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                    .cabinetBody()

                Text("Callout")
                    .cabinetCallout()

                Text("Subheadline")
                    .cabinetSubheadline()

                Text("Footnote")
                    .cabinetFootnote()

                Text("Caption")
                    .cabinetCaption()

                Text("Caption 2")
                    .cabinetCaption2()
            }

          
        }
        .padding()
    }
}
