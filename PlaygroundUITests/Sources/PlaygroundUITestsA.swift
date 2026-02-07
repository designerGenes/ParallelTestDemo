import XCTest

final class PlaygroundUITestsA: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTitleLabelExists() throws {
        XCTAssertTrue(app.staticTexts["titleLabel"].waitForExistence(timeout: 5))
    }

    func testGreetingLabelExists() throws {
        XCTAssertTrue(app.staticTexts["greetingLabel"].waitForExistence(timeout: 5))
    }

    func testTapButtonExists() throws {
        XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
    }

    func testFeatureToggleExists() throws {
        XCTAssertTrue(app.switches["featureToggle"].waitForExistence(timeout: 5))
    }

    func testInputFieldExists() throws {
        XCTAssertTrue(app.textFields["inputField"].waitForExistence(timeout: 5))
    }
}
