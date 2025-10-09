//
//  Font+CabinetGrotesk.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI

extension Font {

    // MARK: - Cabinet Grotesk Font Family

    /// Cabinet Grotesk font family names for individual OTF weights
    private static let cabinetGroteskThin = "CabinetGrotesk-Thin"
    private static let cabinetGroteskExtralight = "CabinetGrotesk-Extralight"
    private static let cabinetGroteskLight = "CabinetGrotesk-Light"
    private static let cabinetGroteskRegular = "CabinetGrotesk-Regular"
    private static let cabinetGroteskMedium = "CabinetGrotesk-Medium"
    private static let cabinetGroteskBold = "CabinetGrotesk-Bold"
    private static let cabinetGroteskExtrabold = "CabinetGrotesk-Extrabold"
    private static let cabinetGroteskBlack = "CabinetGrotesk-Black"

    // MARK: - Dynamic Type Styles with Cabinet Grotesk

    /// Large Title style with Cabinet Grotesk (34pt base, scales with Dynamic Type)
    static var cabinetLargeTitle: Font {
        .custom(cabinetGroteskBlack, size: 34, relativeTo: .largeTitle)
    }

    /// Title 1 style with Cabinet Grotesk (28pt base, scales with Dynamic Type)
    static var cabinetTitle: Font {
        .custom(cabinetGroteskBold, size: 28, relativeTo: .title)
    }

    /// Title 2 style with Cabinet Grotesk (22pt base, scales with Dynamic Type)
    static var cabinetTitle2: Font {
        .custom(cabinetGroteskBold, size: 22, relativeTo: .title2)
    }

    /// Title 3 style with Cabinet Grotesk (20pt base, scales with Dynamic Type)
    static var cabinetTitle3: Font {
        .custom(cabinetGroteskMedium, size: 20, relativeTo: .title3)
    }

    /// Headline style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetHeadline: Font {
        .custom(cabinetGroteskMedium, size: 17, relativeTo: .headline)
    }

    /// Body style with Cabinet Grotesk (17pt base, scales with Dynamic Type)
    static var cabinetBody: Font {
        .custom(cabinetGroteskRegular, size: 17, relativeTo: .body)
    }

    /// Callout style with Cabinet Grotesk (16pt base, scales with Dynamic Type)
    static var cabinetCallout: Font {
        .custom(cabinetGroteskRegular, size: 16, relativeTo: .callout)
    }

    /// Subheadline style with Cabinet Grotesk (15pt base, scales with Dynamic Type)
    static var cabinetSubheadline: Font {
        .custom(cabinetGroteskMedium, size: 15, relativeTo: .subheadline)
    }

    /// Footnote style with Cabinet Grotesk (13pt base, scales with Dynamic Type)
    static var cabinetFootnote: Font {
        .custom(cabinetGroteskMedium, size: 13, relativeTo: .footnote)
    }

    /// Caption 1 style with Cabinet Grotesk (12pt base, scales with Dynamic Type)
    static var cabinetCaption: Font {
        .custom(cabinetGroteskMedium, size: 12, relativeTo: .caption)
    }

    /// Caption 2 style with Cabinet Grotesk (11pt base, scales with Dynamic Type)
    static var cabinetCaption2: Font {
        .custom(cabinetGroteskRegular, size: 11, relativeTo: .caption2)
    }

    // MARK: - Custom Sizes with Cabinet Grotesk

    /// Custom size Cabinet Grotesk font with dynamic type support
    /// - Parameters:
    ///   - size: Base font size
    ///   - weight: Font weight (defaults to regular)
    ///   - relativeTo: Text style to scale relative to for Dynamic Type
    /// - Returns: Custom sized Cabinet Grotesk font
    static func cabinet(size: CGFloat, weight: CabinetGroteskWeight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom(weight.fontName, size: size, relativeTo: textStyle)
    }

    /// Fixed size Cabinet Grotesk font (does not scale with Dynamic Type)
    /// - Parameters:
    ///   - size: Fixed font size
    ///   - weight: Font weight (defaults to regular)
    /// - Returns: Fixed size Cabinet Grotesk font
    static func cabinetFixed(size: CGFloat, weight: CabinetGroteskWeight = .regular) -> Font {
        .custom(weight.fontName, fixedSize: size)
    }

    // MARK: - Weight Helper

    /// Cabinet Grotesk weight options
    enum CabinetGroteskWeight {
        case thin
        case extralight
        case light
        case regular
        case medium
        case bold
        case extrabold
        case black

        var fontName: String {
            switch self {
            case .thin: return "CabinetGrotesk-Thin"
            case .extralight: return "CabinetGrotesk-Extralight"
            case .light: return "CabinetGrotesk-Light"
            case .regular: return "CabinetGrotesk-Regular"
            case .medium: return "CabinetGrotesk-Medium"
            case .bold: return "CabinetGrotesk-Bold"
            case .extrabold: return "CabinetGrotesk-Extrabold"
            case .black: return "CabinetGrotesk-Black"
            }
        }
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
    func cabinet(size: CGFloat, weight: Font.CabinetGroteskWeight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        self.font(.cabinet(size: size, weight: weight, relativeTo: textStyle))
    }

    /// Apply fixed size Cabinet Grotesk font (no dynamic type scaling)
    func cabinetFixed(size: CGFloat, weight: Font.CabinetGroteskWeight = .regular) -> some View {
        self.font(.cabinetFixed(size: size, weight: weight))
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

            Text("Font Weights")
                .font(.headline)
                .padding(.top)

            Group {
                Text("Thin")
                    .cabinet(size: 20, weight: .thin)

                Text("Extralight")
                    .cabinet(size: 20, weight: .extralight)

                Text("Light")
                    .cabinet(size: 20, weight: .light)

                Text("Regular")
                    .cabinet(size: 20, weight: .regular)

                Text("Medium")
                    .cabinet(size: 20, weight: .medium)

                Text("Bold")
                    .cabinet(size: 20, weight: .bold)

                Text("Extrabold")
                    .cabinet(size: 20, weight: .extrabold)

                Text("Black")
                    .cabinet(size: 20, weight: .black)
            }

            Divider()

            Group {
                Text("Custom Size 24pt")
                    .cabinet(size: 24)

                Text("Custom Size 32pt Bold (relative to title)")
                    .cabinet(size: 32, weight: .bold, relativeTo: .title)

                Text("Fixed Size 18pt Medium (no scaling)")
                    .cabinetFixed(size: 18, weight: .medium)
            }
        }
        .padding()
    }
}
