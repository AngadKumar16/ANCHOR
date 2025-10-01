import XCTest
@testable import Anchor

final class NotificationPreferencesViewTests: XCTestCase {
    func testScaffold() {
        let vm = NotificationPreferencesViewModel()
        XCTAssertNotNil(vm)
    }
}
