//
//  Font+CabinetGrotesk.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI

extension Font {


    // MARK: - Dynamic Type Styles with Cabinet Grotesk

    /// Large Title style with Cabinet Grotesk (34pt base, scales with Dynamic Type)
    static var cabinetLargeTitle: Font {
        .custom(
            FigFontFamily.CabinetGrotesk.bold.name,
            size: 34,
            relativeTo: .largeTitle
        )
    }

    /// Title 1 style with Cabinet Grotesk (28pt base, scales with Dynamic Type)
    static var cabinetTitle: Font {
        .custom(FigFontFamily.CabinetGrotesk.bold.name, size: 28, relativeTo: .title)
    }

    /// Title 2 style with Cabinet Grotesk (22pt base, scales with Dynamic Type)
    static var cabinetTitle2: Font {
        .custom(FigFontFamily.CabinetGrotesk.bold.name, size: 22, relativeTo: .title2)
    }

    /// Title 3 style with Cabinet Grotesk (20pt base, scales with Dynamic Type)
    static var cabinetTitle3: Font {
        .custom(FigFontFamily.CabinetGrotesk.medium.name, size: 20, relativeTo: .title3)
    }

    /// Headline style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetHeadline: Font {
        .custom(FigFontFamily.CabinetGrotesk.medium.name, size: 17, relativeTo: .headline)
    }

    /// Body style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetBody: Font {
        .custom(FigFontFamily.CabinetGrotesk.regular.name, size: 17, relativeTo: .body)
    }

    /// Callout style with Cabinet Grotesk (16pt base, scales with Dynamic Type)
    static var cabinetCallout: Font {
        .custom(FigFontFamily.CabinetGrotesk.regular.name, size: 16, relativeTo: .callout)
    }

    /// Subheadline style with Cabinet Grotesk (15pt base, scales with Dynamic Type)
    static var cabinetSubheadline: Font {
        .custom(FigFontFamily.CabinetGrotesk.medium.name, size: 15, relativeTo: .subheadline)
    }

    /// Footnote style with Cabinet Grotesk (13pt base, scales with Dynamic Type)
    static var cabinetFootnote: Font {
        .custom(FigFontFamily.CabinetGrotesk.medium.name, size: 13, relativeTo: .footnote)
    }

    /// Caption 1 style with Cabinet Grotesk (12pt base, scales with Dynamic Type)
    static var cabinetCaption: Font {
        .custom(FigFontFamily.CabinetGrotesk.medium.name, size: 12, relativeTo: .caption)
    }

    /// Caption 2 style with Cabinet Grotesk (11pt base, scales with Dynamic Type)
    static var cabinetCaption2: Font {
        .custom(FigFontFamily.CabinetGrotesk.regular.name, size: 11, relativeTo: .caption2)
    }

   
}

// MARK: - View Extension for Easy Application

extension View {

    /// Apply Cabinet Grotesk large title style
    func cabinetLargeTitle() -> some View {
        self.font(.cabinetLargeTitle)
    }

    /// Apply Cabinet Grotesk title style
    func cabinetTitle() -> some View {
        self.font(.cabinetTitle)
    }

    /// Apply Cabinet Grotesk title 2 style
    func cabinetTitle2() -> some View {
        self.font(.cabinetTitle2)
    }

    /// Apply Cabinet Grotesk title 3 style
    func cabinetTitle3() -> some View {
        self.font(.cabinetTitle3)
    }

    /// Apply Cabinet Grotesk headline style
    func cabinetHeadline() -> some View {
        self.font(.cabinetHeadline)
    }

    /// Apply Cabinet Grotesk body style
    func cabinetBody() -> some View {
        self.font(.cabinetBody)
    }

    /// Apply Cabinet Grotesk callout style
    func cabinetCallout() -> some View {
        self.font(.cabinetCallout)
    }

    /// Apply Cabinet Grotesk subheadline style
    func cabinetSubheadline() -> some View {
        self.font(.cabinetSubheadline)
    }

    /// Apply Cabinet Grotesk footnote style
    func cabinetFootnote() -> some View {
        self.font(.cabinetFootnote)
    }

    /// Apply Cabinet Grotesk caption style
    func cabinetCaption() -> some View {
        self.font(.cabinetCaption)
    }

    /// Apply Cabinet Grotesk caption 2 style
    func cabinetCaption2() -> some View {
        self.font(.cabinetCaption2)
    }

}

// MARK: - Preview Helper

#Preview("Cabinet Grotesk Font Styles") {
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
