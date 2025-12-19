import SwiftData
import Foundation

// MARK: - Schema V1 (Original)
enum SpoolSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Spool.self]
    }

    @Model
    final class Spool {
        var id: UUID
        var manufacturer: String
        var type: FilamentType
        var color: String = ""
        var originalWeight: Double
        var currentWeight: Double
        var createdAt: Date

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

    enum FilamentType: String, Codable, CaseIterable {
        case pla = "PLA"
        case petg = "PETG"

        var displayName: String { self.rawValue }
    }
}

// MARK: - Schema V2 (With NFC Support)
enum SpoolSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Spool.self]
    }

    @Model
    final class Spool {
        var id: UUID
        var manufacturer: String
        var type: FilamentType
        var color: String = ""
        var originalWeight: Double
        var currentWeight: Double
        var createdAt: Date
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

    enum FilamentType: String, Codable, CaseIterable {
        case pla = "PLA"
        case petg = "PETG"

        var displayName: String { self.rawValue }
    }
}

// MARK: - Migration Plan
enum SpoolMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SpoolSchemaV1.self, SpoolSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SpoolSchemaV1.self,
        toVersion: SpoolSchemaV2.self
    )
}
