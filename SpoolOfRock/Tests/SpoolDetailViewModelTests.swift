import XCTest
@testable import SpoolOfRock

@MainActor
final class SpoolDetailViewModelTests: XCTestCase {
    var repository: SpoolRepository!
    var spool: Spool!

    override func setUp() async throws {
        spool = Spool(
            manufacturer: "TestCo",
            type: .pla,
            color: "Purple",
            originalWeight: 1000,
            currentWeight: 800
        )
        let implementation = InMemorySpoolRepository(initialSpools: [spool])
        repository = SpoolRepository(implementation: implementation)
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    override func tearDown() {
        repository = nil
        spool = nil
    }

    func testViewModelInitialization() {
        // Given/When
        let viewModel = SpoolDetailViewModel(spool: spool, repository: repository)

        // Then
        XCTAssertEqual(viewModel.manufacturer, "TestCo")
        XCTAssertEqual(viewModel.type, .pla)
        XCTAssertEqual(viewModel.color, "Purple")
        XCTAssertEqual(viewModel.originalWeight, 1000)
        XCTAssertEqual(viewModel.currentWeight, 800)
    }

    func testRemainingPercentageCalculation() {
        // Given
        let viewModel = SpoolDetailViewModel(spool: spool, repository: repository)

        // When/Then
        XCTAssertEqual(viewModel.remainingPercentage, 80.0, accuracy: 0.01)

        // When - change current weight
        viewModel.currentWeight = 500

        // Then
        XCTAssertEqual(viewModel.remainingPercentage, 50.0, accuracy: 0.01)
    }

    func testRemainingPercentageWithZeroOriginal() {
        // Given
        let zeroSpool = Spool(
            manufacturer: "Zero",
            type: .pla,
            color: "Clear",
            originalWeight: 0,
            currentWeight: 0
        )
        let viewModel = SpoolDetailViewModel(spool: zeroSpool, repository: repository)

        // When/Then
        XCTAssertEqual(viewModel.remainingPercentage, 0.0)
    }

    func testSaveUpdatesRepository() async throws {
        // Given
        let viewModel = SpoolDetailViewModel(spool: spool, repository: repository)
        viewModel.currentWeight = 600

        // When
        viewModel.save()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(spool.currentWeight, 600)
        XCTAssertEqual(repository.spools.first?.currentWeight, 600)
    }

    func testViewModelPreservesReadOnlyProperties() {
        // Given
        let viewModel = SpoolDetailViewModel(spool: spool, repository: repository)

        // When - modify current weight
        viewModel.currentWeight = 500

        // Then - read-only properties unchanged
        XCTAssertEqual(viewModel.manufacturer, "TestCo")
        XCTAssertEqual(viewModel.type, .pla)
        XCTAssertEqual(viewModel.color, "Purple")
        XCTAssertEqual(viewModel.originalWeight, 1000)
    }
}
