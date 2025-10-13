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
    static var LargeTitle: Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }

    /// Title 1 style with SF Pro Rounded (28pt base, scales with Dynamic Type)
    static var Title: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    /// Title 2 style with SF Pro Rounded (22pt base, scales with Dynamic Type)
    static var Title2: Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }

    /// Title 3 style with SF Pro Rounded (20pt base, scales with Dynamic Type)
    static var Title3: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    /// Headline style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var Headline: Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    /// Body style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var Body: Font {
        .system(size: 17, weight: .regular, design: .rounded)
    }

    /// Callout style with SF Pro Rounded (16pt base, scales with Dynamic Type)
    static var Callout: Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    /// Subheadline style with SF Pro Rounded (15pt base, scales with Dynamic Type)
    static var Subheadline: Font {
        .system(size: 15, weight: .semibold, design: .rounded)
    }

    /// Footnote style with SF Pro Rounded (13pt base, scales with Dynamic Type)
    static var Footnote: Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }

    /// Caption 1 style with SF Pro Rounded (12pt base, scales with Dynamic Type)
    static var Caption: Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }

    /// Caption 2 style with SF Pro Rounded (11pt base, scales with Dynamic Type)
    static var Caption2: Font {
        .system(size: 11, weight: .regular, design: .rounded)
    }


}

// MARK: - View Extension for Easy Application

extension View {

    /// Apply SF Pro Rounded large title style
    func LargeTitle() -> some View {
        self.font(.LargeTitle)
    }

    /// Apply SF Pro Rounded title style
    func Title() -> some View {
        self.font(.Title)
    }

    /// Apply SF Pro Rounded title 2 style
    func Title2() -> some View {
        self.font(.Title2)
    }

    /// Apply SF Pro Rounded title 3 style
    func Title3() -> some View {
        self.font(.Title3)
    }

    /// Apply SF Pro Rounded headline style
    func Headline() -> some View {
        self.font(.Headline)
    }

    /// Apply SF Pro Rounded body style
    func Body() -> some View {
        self.font(.Body)
    }

    /// Apply SF Pro Rounded callout style
    func Callout() -> some View {
        self.font(.Callout)
    }

    /// Apply SF Pro Rounded subheadline style
    func Subheadline() -> some View {
        self.font(.Subheadline)
    }

    /// Apply SF Pro Rounded footnote style
    func Footnote() -> some View {
        self.font(.Footnote)
    }

    /// Apply SF Pro Rounded caption style
    func Caption() -> some View {
        self.font(.Caption)
    }

    /// Apply SF Pro Rounded caption 2 style
    func Caption2() -> some View {
        self.font(.Caption2)
    }

}

// MARK: - Preview Helper

#Preview("SF Pro Rounded Font Styles") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Large Title")
                    .LargeTitle()

                Text("Title")
                    .Title()

                Text("Title 2")
                    .Title2()

                Text("Title 3")
                    .Title3()

                Text("Headline")
                    .Headline()
            }

            Group {
                Text("Body Text - Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                    .Body()

                Text("Callout")
                    .Callout()

                Text("Subheadline")
                    .Subheadline()

                Text("Footnote")
                    .Footnote()

                Text("Caption")
                    .Caption()

                Text("Caption 2")
                    .Caption2()
            }

          
        }
        .padding()
    }
}
