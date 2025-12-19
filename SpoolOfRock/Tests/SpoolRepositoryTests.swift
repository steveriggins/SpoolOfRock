import XCTest
@testable import SpoolOfRock

@MainActor
final class SpoolRepositoryTests: XCTestCase {
    var repository: SpoolRepository!

    override func setUp() async throws {
        let implementation = InMemorySpoolRepository()
        repository = SpoolRepository(implementation: implementation)
        // Wait for initial refresh
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() {
        repository = nil
    }

    func testAddSpool() async throws {
        // Given
        let spool = Spool(
            manufacturer: "TestCo",
            type: .pla,
            color: "Red",
            originalWeight: 1000,
            currentWeight: 800
        )

        // When
        repository.add(spool)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.spools.count, 1)
        XCTAssertEqual(repository.spools.first?.manufacturer, "TestCo")
        XCTAssertEqual(repository.spools.first?.type, .pla)
        XCTAssertEqual(repository.spools.first?.originalWeight, 1000)
        XCTAssertEqual(repository.spools.first?.currentWeight, 800)
        XCTAssertNil(repository.error)
    }

    func testDeleteSpool() async throws {
        // Given
        let spool = Spool(
            manufacturer: "TestCo",
            type: .pla,
            color: "Blue",
            originalWeight: 1000,
            currentWeight: 800
        )
        repository.add(spool)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(repository.spools.count, 1)

        // When
        repository.delete(spool)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(repository.spools.isEmpty)
        XCTAssertNil(repository.error)
    }

    func testUpdateSpool() async throws {
        // Given
        let spool = Spool(
            manufacturer: "TestCo",
            type: .pla,
            color: "Green",
            originalWeight: 1000,
            currentWeight: 800
        )
        repository.add(spool)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        spool.currentWeight = 600
        repository.update(spool)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.spools.first?.currentWeight, 600)
        XCTAssertNil(repository.error)
    }

    func testDeleteAtOffsets() async throws {
        // Given
        let spool1 = Spool(manufacturer: "Test1", type: .pla, color: "Yellow", originalWeight: 1000, currentWeight: 800)
        let spool2 = Spool(manufacturer: "Test2", type: .petg, color: "Orange", originalWeight: 1000, currentWeight: 600)
        repository.add(spool1)
        repository.add(spool2)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(repository.spools.count, 2)

        // When
        repository.delete(at: IndexSet(integer: 0))
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.spools.count, 1)
        XCTAssertNil(repository.error)
    }

    func testSpoolsSortedByCreationDate() async throws {
        // Given
        let spool1 = Spool(manufacturer: "First", type: .pla, color: "Black", originalWeight: 1000, currentWeight: 800)
        try await Task.sleep(nanoseconds: 10_000_000) // Small delay
        let spool2 = Spool(manufacturer: "Second", type: .petg, color: "White", originalWeight: 1000, currentWeight: 600)

        // When
        repository.add(spool1)
        repository.add(spool2)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.spools.count, 2)
        XCTAssertEqual(repository.spools[0].manufacturer, "Second") // Newest first
        XCTAssertEqual(repository.spools[1].manufacturer, "First")
        XCTAssertNil(repository.error)
    }
}
