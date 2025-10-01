import XCTest
@testable import Anchor

final class InitialSyncImplementationViewTests: XCTestCase {
    func testScaffold() {
        let vm = InitialSyncImplementationViewModel()
        XCTAssertNotNil(vm)
    }
}
