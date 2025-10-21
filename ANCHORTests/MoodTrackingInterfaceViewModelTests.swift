import XCTest
@testable import Anchor

final class MoodTrackingInterfaceViewModelTests: XCTestCase {
    func testScaffold() async throws {
        let vm = MoodTrackingInterfaceViewModelViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
