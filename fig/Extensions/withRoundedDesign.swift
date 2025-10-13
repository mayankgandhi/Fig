//
//  Rounded.swift
//  fig
//
//  Created by Mayank Gandhi on 13/10/25.
//

import UIKit

extension UIFont {
    /// Returns a rounded variant of the system font
    func withRoundedDesign() -> UIFont {
        if let descriptor = fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        return self
    }
}
