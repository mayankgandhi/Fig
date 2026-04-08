//
//  TickerDesignKitConfiguration.swift
//  Ticker
//
//  Created on 2025.
//

import SwiftUI
import DesignKit

/// Ticker-specific DesignKit configuration
extension DesignKitConfiguration {
    
    /// Create Ticker theme configuration
    static var ticker: DesignKitConfiguration {
        let colors = ColorConfiguration(
            primary: Color(red: 0.976, green: 0.451, blue: 0.188), // #F97330
            primaryDark: Color(red: 0.914, green: 0.337, blue: 0.106), // #E9561B
            accent: Color(red: 0.976, green: 0.616, blue: 0.169), // #F99D2B
            success: Color(red: 0.518, green: 0.800, blue: 0.086), // #84CC16
            warning: Color(red: 0.937, green: 0.267, blue: 0.267), // #EF4444
            danger: Color(red: 0.925, green: 0.247, blue: 0.600), // #EC4899
            scheduled: Color(red: 0.976, green: 0.537, blue: 0.278), // #F98947
            running: Color(red: 0.518, green: 0.800, blue: 0.086), // #84CC16
            paused: Color(red: 0.580, green: 0.639, blue: 0.722), // #94A3B8
            alerting: Color(red: 0.851, green: 0.275, blue: 0.937) // #D946EF
        )
        
        let typography = TypographyConfiguration(
            fontDesign: .rounded
        )
        
        return DesignKitConfiguration(
            colors: colors,
            typography: typography
        )
    }
}
