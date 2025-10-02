import XCTest
@testable import Anchor

final class ConflictResolutionViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = ConflictResolutionViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
