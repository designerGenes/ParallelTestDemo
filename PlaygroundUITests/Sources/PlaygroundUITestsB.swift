import XCTest

final class PlaygroundUITestsB: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTitleLabelText() throws {
        let label = app.staticTexts["titleLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertEqual(label.label, "Parallel Test Demo")
    }

    func testGreetingLabelText() throws {
        let label = app.staticTexts["greetingLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertEqual(label.label, "Hello from Playground!")
    }

    func testTapButtonTappable() throws {
        let button = app.buttons["tapButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(true)
    }

    func testToggleIsEnabled() throws {
        let toggle = app.switches["featureToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertTrue(toggle.isEnabled)
    }

    func testInputFieldIsHittable() throws {
        let field = app.textFields["inputField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(field.isHittable)
    }
}
