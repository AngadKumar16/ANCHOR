import XCTest
@testable import Anchor

final class SessionManagementViewTests: XCTestCase {
    func testScaffold() {
        let vm = SessionManagementViewModel()
        XCTAssertNotNil(vm)
    }
}
