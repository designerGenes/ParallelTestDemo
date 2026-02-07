import XCTest

final class PlaygroundUITestsC: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunches() throws {
        XCTAssertTrue(app.waitForExistence(timeout: 5))
    }

    func testMultipleElementsExist() throws {
        XCTAssertTrue(app.staticTexts["titleLabel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tapButton"].exists)
    }

    func testNavigationBarAbsent() throws {
        XCTAssertTrue(app.staticTexts["titleLabel"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars.element.exists)
    }

    func testStaticTextCount() throws {
        XCTAssertTrue(app.staticTexts["titleLabel"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.staticTexts.count, 2)
    }

    func testButtonLabelText() throws {
        let button = app.buttons["tapButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertEqual(button.label, "Tap Me")
    }
}
