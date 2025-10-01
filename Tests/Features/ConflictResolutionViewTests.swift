import XCTest
@testable import Anchor

final class ConflictResolutionViewTests: XCTestCase {
    func testScaffold() {
        let vm = ConflictResolutionViewModel()
        XCTAssertNotNil(vm)
    }
}
