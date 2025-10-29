//
//  Font+SFProRounded.swift
//  fig
//
//  SF Pro Rounded font extension for consistent typography
//  Provides view modifiers for all Dynamic Type styles
//

import SwiftUI

public extension View {

    /// Apply SF Pro Rounded large title style
    public func LargeTitle() -> some View {
        self.font(.LargeTitle)
    }

    /// Apply SF Pro Rounded title style
    public func Title() -> some View {
        self.font(.Title)
    }

    /// Apply SF Pro Rounded title 2 style
    public func Title2() -> some View {
        self.font(.Title2)
    }

    /// Apply SF Pro Rounded title 3 style
    public func Title3() -> some View {
        self.font(.Title3)
    }

    /// Apply SF Pro Rounded headline style
    public func Headline() -> some View {
        self.font(.Headline)
    }

    /// Apply SF Pro Rounded body style
    public func Body() -> some View {
        self.font(.Body)
    }

    /// Apply SF Pro Rounded callout style
    public func Callout() -> some View {
        self.font(.Callout)
    }

    /// Apply SF Pro Rounded subheadline style
    public func Subheadline() -> some View {
        self.font(.Subheadline)
    }

    /// Apply SF Pro Rounded footnote style
    public func Footnote() -> some View {
        self.font(.Footnote)
    }

    /// Apply SF Pro Rounded caption style
    public func Caption() -> some View {
        self.font(.Caption)
    }

    /// Apply SF Pro Rounded caption 2 style
    public func Caption2() -> some View {
        self.font(.Caption2)
    }

    // MARK: - Consistent Typography Hierarchy
    
    /// Apply consistent time display font (28pt) - for card time displays
    public func TimeDisplay() -> some View {
        self.font(.system(size: 28, weight: .bold, design: .rounded))
    }
    
    /// Apply consistent ticker title font (18pt) - for ticker names
    public func TickerTitle() -> some View {
        self.font(.system(size: 18, weight: .semibold, design: .rounded))
    }
    
    /// Apply consistent detail text font (15pt) - for schedule details
    public func DetailText() -> some View {
        self.font(.system(size: 15, weight: .medium, design: .rounded))
    }
    
    /// Apply consistent button text font (14pt) - for buttons and labels
    public func ButtonText() -> some View {
        self.font(.system(size: 14, weight: .semibold, design: .rounded))
    }
    
    /// Apply consistent small text font (12pt) - for secondary info
    public func SmallText() -> some View {
        self.font(.system(size: 12, weight: .medium, design: .rounded))
    }

}

fileprivate extension Font {

    // MARK: - Dynamic Type Styles with SF Pro Rounded

    /// Large Title style with SF Pro Rounded (34pt base, scales with Dynamic Type)
    static var LargeTitle: Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }

    /// Title 1 style with SF Pro Rounded (28pt base, scales with Dynamic Type)
    static var Title: Font {
        .system(.title, design: .rounded, weight: .bold)
    }

    /// Title 2 style with SF Pro Rounded (22pt base, scales with Dynamic Type)
    static var Title2: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }

    /// Title 3 style with SF Pro Rounded (20pt base, scales with Dynamic Type)
    static var Title3: Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }

    /// Headline style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var Headline: Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }

    /// Body style with SF Pro Rounded (17pt base, scales with Dynamic Type)
    static var Body: Font {
        .system(.body, design: .rounded, weight: .regular)
    }

    /// Callout style with SF Pro Rounded (16pt base, scales with Dynamic Type)
    static var Callout: Font {
        .system(.callout, design: .rounded, weight: .regular)
    }

    /// Subheadline style with SF Pro Rounded (15pt base, scales with Dynamic Type)
    static var Subheadline: Font {
        .system(.subheadline, design: .rounded, weight: .semibold)
    }

    /// Footnote style with SF Pro Rounded (13pt base, scales with Dynamic Type)
    static var Footnote: Font {
        .system(.footnote, design: .rounded, weight: .medium)
    }

    /// Caption 1 style with SF Pro Rounded (12pt base, scales with Dynamic Type)
    static var Caption: Font {
        .system(.caption, design: .rounded, weight: .medium)
    }

    /// Caption 2 style with SF Pro Rounded (11pt base, scales with Dynamic Type)
    static var Caption2: Font {
        .system(.caption2, design: .rounded, weight: .regular)
    }

}

// MARK: - View Extension for Easy Application



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
