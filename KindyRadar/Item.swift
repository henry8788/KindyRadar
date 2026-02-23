//
//  Item.swift
//  KindyRadar
//
//  Created by Henry Lin on 2026/2/23.
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
