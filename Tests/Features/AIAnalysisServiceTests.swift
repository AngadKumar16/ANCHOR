import XCTest
@testable import Anchor

final class AIAnalysisServiceTests: XCTestCase {
    func testScaffold() async throws {
        let vm = AIAnalysisServiceViewModel()
        vm.draftTitle = "t"
        await vm.saveDraft()
        XCTAssertTrue(!vm.items.isEmpty)
    }
}
