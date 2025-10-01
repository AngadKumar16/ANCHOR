import XCTest
@testable import Anchor

final class MoodTrackingInterfaceViewTests: XCTestCase {
    func testScaffold() {
        let vm = MoodTrackingInterfaceViewModel()
        XCTAssertNotNil(vm)
    }
}
