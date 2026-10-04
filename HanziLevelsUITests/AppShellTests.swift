import XCTest

final class AppShellTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchScreenshot() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["level.1"].waitForExistence(timeout: 5))

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Levels launch screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testEveryLevelOpensItsEmptyStateAndReturnsHome() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))

        for level in 1...5 {
            let card = app.buttons["level.\(level)"]
            if !card.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(card.exists)
            card.tap()

            let navigationBar = app.navigationBars["HSK \(level)"]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["No vocabulary yet"].exists)
            navigationBar.buttons.firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))
        }
    }

    func testSourcesOpensWithoutABundledDataset() {
        let app = XCUIApplication()
        app.launch()

        let sources = app.buttons["sources"]
        if !sources.isHittable {
            app.swipeUp()
        }
        sources.tap()

        let navigationBar = app.navigationBars["Sources & Licenses"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No sources bundled yet"].exists)
        navigationBar.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))
    }
}
