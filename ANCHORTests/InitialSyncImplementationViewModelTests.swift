import XCTest
@testable import Anchor

final class InitialSyncImplementationViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = InitialSyncImplementationViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
