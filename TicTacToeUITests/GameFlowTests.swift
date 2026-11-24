import XCTest

final class GameFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        XCTAssertTrue(app.buttons["cell0"].waitForExistence(timeout: 8))
    }

    private func play(_ moves: [Int]) {
        for index in moves {
            let cell = app.buttons["cell\(index)"]
            XCTAssertTrue(cell.isEnabled)
            cell.tap()
        }
    }

    private func saveScreen(_ name: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testWinDrawAndAlternatingStarter() {
        saveScreen("01-start")
        play([0, 2, 4, 6])
        XCTAssertFalse(app.buttons["cell0"].isEnabled)
        saveScreen("02-playing")

        play([8])
        for index in [0, 4, 8] {
            let value = app.buttons["cell\(index)"].value as? String
            XCTAssertTrue(value?.contains("خط الفوز") == true)
        }
        XCTAssertFalse(app.buttons["cell1"].isEnabled)
        XCTAssertEqual(app.descendants(matching: .any)["scoreX"].value as? String, "١")
        saveScreen("03-win")

        app.buttons["newRound"].tap()
        play([0])
        XCTAssertEqual(app.buttons["cell0"].value as? String, "أو")
        play([1, 2, 4, 3, 5, 7, 6, 8])
        XCTAssertFalse(app.buttons["cell8"].isEnabled)
        XCTAssertTrue(app.staticTexts["gameStatus"].label.contains("تعادل"))
        XCTAssertEqual(app.descendants(matching: .any)["scoreDraw"].value as? String, "١")
        XCTAssertEqual(app.descendants(matching: .any)["scoreX"].value as? String, "١")
        saveScreen("04-draw")
    }

    func testRestartConfirmationPreservesPlayOnCancel() {
        play([4])
        app.buttons["newRound"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.buttons["متابعة اللعب"].tap()
        XCTAssertEqual(app.buttons["cell4"].value as? String, "إكس")
        app.buttons["newRound"].tap()
        app.alerts.buttons["إعادة الجولة"].tap()
        XCTAssertTrue(app.buttons["cell4"].isEnabled)
        play([0])
        XCTAssertEqual(app.buttons["cell0"].value as? String, "إكس")
    }
}
