import XCTest
@testable import Anchor

final class ImplementBackuprestoreFunctionalityViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = ImplementBackuprestoreFunctionalityViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
