import Foundation

enum FilamentType: String, Codable, CaseIterable {
    case pla = "PLA"
    case petg = "PETG"

    var displayName: String {
        self.rawValue
    }
}
