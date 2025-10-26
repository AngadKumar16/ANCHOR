import XCTest
@testable import Anchor

final class EntryCategorizationtaggingViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = EntryCategorizationtaggingViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
