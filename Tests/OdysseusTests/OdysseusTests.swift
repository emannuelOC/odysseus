import XCTest
@testable import Odysseus

final class OdysseusTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        if #available(iOS 13.0, *) {
            XCTAssert(true)
        } else {
            // Fallback on earlier versions
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
