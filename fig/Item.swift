//
//  Item.swift
//  fig
//
//  Created by Mayank Gandhi on 04/10/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
