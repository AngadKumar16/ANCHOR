import XCTest
@testable import Anchor

final class DashboardViewTests: XCTestCase {
    func testScaffold() async throws {
        let vm = DashboardViewViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
