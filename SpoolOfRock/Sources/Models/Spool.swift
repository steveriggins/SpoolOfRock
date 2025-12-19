import Foundation
import SwiftData

@Model
final class Spool {
    var id: UUID = UUID()
    var manufacturer: String = ""
    var type: FilamentType = FilamentType.pla
    var color: String = ""
    var originalWeight: Double = 0 // in grams
    var currentWeight: Double = 0 // in grams
    var createdAt: Date = Date()
    var nfcTagIdentifier: String? = nil

    init(manufacturer: String, type: FilamentType, color: String, originalWeight: Double, currentWeight: Double) {
        self.id = UUID()
        self.manufacturer = manufacturer
        self.type = type
        self.color = color
        self.originalWeight = originalWeight
        self.currentWeight = currentWeight
        self.createdAt = Date()
    }

    var remainingPercentage: Double {
        guard originalWeight > 0 else { return 0 }
        return (currentWeight / originalWeight) * 100
    }
}
