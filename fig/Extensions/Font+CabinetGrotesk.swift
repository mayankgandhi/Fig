//
//  Font+CabinetGrotesk.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI

extension Font {

    // MARK: - Cabinet Grotesk Font Family

    /// Cabinet Grotesk is a variable font that supports dynamic weights
    /// The font family name for the variable font
    private static let cabinetGroteskFamily = "Cabinet Grotesk Variable"

    // MARK: - Dynamic Type Styles with Cabinet Grotesk

    /// Large Title style with Cabinet Grotesk (34pt base, scales with Dynamic Type)
    static var cabinetLargeTitle: Font {
        .custom(cabinetGroteskFamily, size: 34, relativeTo: .largeTitle)
        .weight(.black)
    }

    /// Title 1 style with Cabinet Grotesk (28pt base, scales with Dynamic Type)
    static var cabinetTitle: Font {
        .custom(cabinetGroteskFamily, size: 28, relativeTo: .title)
        .weight(.bold)
    }

    /// Title 2 style with Cabinet Grotesk (22pt base, scales with Dynamic Type)
    static var cabinetTitle2: Font {
        .custom(cabinetGroteskFamily, size: 22, relativeTo: .title2)
        .weight(.bold)
    }

    /// Title 3 style with Cabinet Grotesk (20pt base, scales with Dynamic Type)
    static var cabinetTitle3: Font {
        .custom(cabinetGroteskFamily, size: 20, relativeTo: .title3)
        .weight(.semibold)
    }

    /// Headline style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetHeadline: Font {
        .custom(cabinetGroteskFamily, size: 17, relativeTo: .headline)
        .weight(.semibold)
    }

    /// Body style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetBody: Font {
        .custom(cabinetGroteskFamily, size: 17, relativeTo: .body)
    }

    /// Callout style with Cabinet Grotesk (16pt base, scales with Dynamic Type)
    static var cabinetCallout: Font {
        .custom(cabinetGroteskFamily, size: 16, relativeTo: .callout)
    }

    /// Subheadline style with Cabinet Grotesk (15pt base, scales with Dynamic Type)
    static var cabinetSubheadline: Font {
        .custom(cabinetGroteskFamily, size: 15, relativeTo: .subheadline)
        .weight(.medium)
    }

    /// Footnote style with Cabinet Grotesk (13pt base, scales with Dynamic Type)
    static var cabinetFootnote: Font {
        .custom(cabinetGroteskFamily, size: 13, relativeTo: .footnote)
        .weight(.medium)
    }

    /// Caption 1 style with Cabinet Grotesk (12pt base, scales with Dynamic Type)
    static var cabinetCaption: Font {
        .custom(cabinetGroteskFamily, size: 12, relativeTo: .caption)
        .weight(.medium)
    }

    /// Caption 2 style with Cabinet Grotesk (11pt base, scales with Dynamic Type)
    static var cabinetCaption2: Font {
        .custom(cabinetGroteskFamily, size: 11, relativeTo: .caption2)
    }

    // MARK: - Custom Sizes with Cabinet Grotesk

    /// Custom size Cabinet Grotesk font with dynamic type support
    /// - Parameters:
    ///   - size: Base font size
    ///   - relativeTo: Text style to scale relative to for Dynamic Type
    /// - Returns: Custom sized Cabinet Grotesk font
    static func cabinet(size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom(cabinetGroteskFamily, size: size, relativeTo: textStyle)
    }

    /// Fixed size Cabinet Grotesk font (does not scale with Dynamic Type)
    /// - Parameter size: Fixed font size
    /// - Returns: Fixed size Cabinet Grotesk font
    static func cabinetFixed(size: CGFloat) -> Font {
        .custom(cabinetGroteskFamily, fixedSize: size)
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

    /// Apply custom size Cabinet Grotesk font with dynamic type support
    func cabinet(size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        self.font(.cabinet(size: size, relativeTo: textStyle))
    }

    /// Apply fixed size Cabinet Grotesk font (no dynamic type scaling)
    func cabinetFixed(size: CGFloat) -> some View {
        self.font(.cabinetFixed(size: size))
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

            Divider()

            Group {
                Text("Custom Size 24pt")
                    .cabinet(size: 24)

                Text("Custom Size 32pt (relative to title)")
                    .cabinet(size: 32, relativeTo: .title)

                Text("Fixed Size 18pt (no scaling)")
                    .cabinetFixed(size: 18)
            }
        }
        .padding()
    }
}
