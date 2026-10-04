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
            scrollToHittable(card, in: app)
            card.tap()

            let navigationBar = app.navigationBars["HSK \(level)"]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["No vocabulary yet"].exists)
            let back = navigationBar.buttons["Levels"]
            XCTAssertTrue(back.waitForExistence(timeout: 5))
            back.tap()
            XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))
        }
    }

    func testSourcesOpensWithoutABundledDataset() {
        let app = XCUIApplication()
        app.launch()

        let sources = app.buttons["sources"]
        scrollToHittable(sources, in: app)
        sources.tap()

        let navigationBar = app.navigationBars["Sources & Licenses"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No sources bundled yet"].exists)
        let back = navigationBar.buttons["Levels"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(app.navigationBars["Levels"].waitForExistence(timeout: 5))
    }

    private func scrollToHittable(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Start each lookup at the top so restored offsets cannot affect the search.
        for _ in 0..<3 {
            app.swipeDown()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing navigation row", file: file, line: line)
        for _ in 0..<5 {
            if element.isHittable {
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Navigation row could not be scrolled into view", file: file, line: line)
    }
}
