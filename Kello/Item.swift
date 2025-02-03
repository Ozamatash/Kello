//
//  Item.swift
//  Kello
//
//  Created by Tuomas Laitila on 3.2.2025.
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
