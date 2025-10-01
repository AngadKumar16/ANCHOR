import XCTest
@testable import Anchor

final class SocialLoginAppleGoogleViewTests: XCTestCase {
    func testScaffold() {
        let vm = SocialLoginAppleGoogleViewModel()
        XCTAssertNotNil(vm)
    }
}
