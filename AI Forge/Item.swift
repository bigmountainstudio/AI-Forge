// Copyright © 2026 Mark Moeykens. All rights reserved. X: @BigMtnStudio

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
