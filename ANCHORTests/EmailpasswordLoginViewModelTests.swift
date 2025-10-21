import XCTest
@testable import Anchor

final class EmailpasswordLoginViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = EmailpasswordLoginViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
