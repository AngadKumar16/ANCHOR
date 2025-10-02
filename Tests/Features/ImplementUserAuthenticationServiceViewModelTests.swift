import XCTest
@testable import Anchor

final class ImplementUserAuthenticationServiceViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = ImplementUserAuthenticationServiceViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
