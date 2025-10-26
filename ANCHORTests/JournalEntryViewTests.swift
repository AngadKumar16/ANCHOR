import XCTest
@testable import Anchor

final class JournalEntryViewTests: XCTestCase {
    func testScaffold() async throws {
        let vm = JournalEntryViewViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
