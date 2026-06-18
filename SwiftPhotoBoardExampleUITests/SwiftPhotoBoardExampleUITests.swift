//
//  SwiftPhotoBoardExampleUITests.swift
//  SwiftPhotoBoardExampleUITests
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import XCTest

final class SwiftPhotoBoardExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testSwiftPhotoBoard() throws {
        let app = XCUIApplication()
        app.launch()
        let cellCount = app.collectionViews.cells.count

        try _testAddSaveItem(app, cellCount)
        try _testEditBackItem(app, cellCount)
        try _testEditSaveItem(app, cellCount)
        try _testDeleteItem(app, cellCount)

        // Wait for SwiftData auto commit
        //Thread.sleep(forTimeInterval: 10)

        app.terminate()
    }

    @MainActor
    private func _testAddSaveItem(_ app: XCUIApplication, _ cellCount: Int)
        throws
    {
        // click Add button
        app.buttons[L(en: "Add Item", ja: "項目を追加")].tap()

        // input Node field
        let noteField = app.textFields["Note"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        noteField.tap()
        let note = UUID().uuidString
        noteField.typeText(note)

        // click "Select Photo" button
        app.buttons[L(en: "Select Photo", ja: "写真を選択")].tap()

        // click First Photo
        let firstPhoto = app.scrollViews.images.firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        firstPhoto.tap()
        XCTAssertTrue(app.images["CapturedPhoto"].waitForExistence(timeout: 10))

        // click Save button
        let saveButton = app.buttons[L(en: "Save", ja: "保存")]
        XCTAssertTrue(waitForEnabled(saveButton, timeout: 5))
        saveButton.tap()

        // assert list item
        XCTAssertTrue(
            app.navigationBars[L(en: "Photo Board", ja: "フォトボード")]
                .waitForExistence(timeout: 5)
        )
        XCTAssertEqual(app.collectionViews.cells.count, cellCount + 1)
    }

    @MainActor
    private func _testEditBackItem(_ app: XCUIApplication, _ cellCount: Int)
        throws
    {
        // click First item
        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
        XCTAssertTrue(
            app.navigationBars[L(en: "Edit Item", ja: "項目を編集")]
                .waitForExistence(timeout: 5)
        )

        // input Node field
        let noteField = app.textFields["Note"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        let originalNote = (noteField.value as? String) ?? ""
        let clearButton = app.buttons["ClearNote"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        noteField.tap()
        let modifiedNote = UUID().uuidString
        noteField.typeText(modifiedNote)

        // click "Take Photo" button
        app.buttons[L(en: "Take Photo", ja: "写真を撮影")].tap()
        let shutter = app.buttons["PhotoCapture"]
        XCTAssertTrue(shutter.waitForExistence(timeout: 10))
        shutter.tap()

        // click "Use Photo" button
        let usePhotoButton = firstExistingButton(
            in: app,
            labels: ["Use Photo", "写真を使用"],
            timeout: 10
        )
        XCTAssertNotNil(usePhotoButton, "Use Photo button not found")
        usePhotoButton?.tap()
        XCTAssertTrue(app.images["CapturedPhoto"].waitForExistence(timeout: 5))

        // click Back button
        let backButton = app.buttons[L(en: "Photo Board", ja: "フォトボード")]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        // assert list item
        XCTAssertTrue(
            app.navigationBars[L(en: "Photo Board", ja: "フォトボード")]
                .waitForExistence(timeout: 5)
        )
        XCTAssertEqual(app.collectionViews.cells.count, cellCount + 1)
        XCTAssertTrue(
            app.staticTexts[originalNote].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts[modifiedNote].exists)
    }

    @MainActor
    private func _testEditSaveItem(_ app: XCUIApplication, _ cellCount: Int)
        throws
    {
        // click First item
        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
        XCTAssertTrue(
            app.navigationBars[L(en: "Edit Item", ja: "項目を編集")]
                .waitForExistence(timeout: 5)
        )

        // input Node field
        let noteField = app.textFields["Note"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        let originalNote = (noteField.value as? String) ?? ""
        let clearButton = app.buttons["ClearNote"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        noteField.tap()
        let editedNote = UUID().uuidString
        noteField.typeText(editedNote)

        // click "Delete Photo" button
        XCTAssertTrue(
            app.images["CapturedPhoto"].waitForExistence(timeout: 10)
        )
        app.buttons[L(en: "Delete Photo", ja: "写真を削除")].tap()
        XCTAssertFalse(
            app.images["CapturedPhoto"].waitForExistence(timeout: 2)
        )

        // click Save Button
        let saveButton = app.buttons[L(en: "Save", ja: "保存")]
        XCTAssertTrue(waitForEnabled(saveButton, timeout: 5))
        saveButton.tap()

        // assert list item
        XCTAssertTrue(
            app.navigationBars[L(en: "Photo Board", ja: "フォトボード")]
                .waitForExistence(timeout: 5)
        )
        XCTAssertEqual(app.collectionViews.cells.count, cellCount + 1)
        XCTAssertTrue(
            app.staticTexts[editedNote].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts[originalNote].exists)
    }

    @MainActor
    private func _testDeleteItem(_ app: XCUIApplication, _ cellCount: Int)
        throws
    {
        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.swipeLeft()

        let deleteButton = firstExistingButton(
            in: app,
            labels: ["Delete", "削除"],
            timeout: 5
        )
        XCTAssertNotNil(deleteButton, "Delete button not found")
        deleteButton?.tap()

        XCTAssertEqual(app.collectionViews.cells.count, cellCount)
    }

    private var isJapanese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
    }

    private func L(en: String, ja: String) -> String {
        isJapanese ? ja : en
    }

    @MainActor
    private func firstExistingButton(
        in app: XCUIApplication,
        labels: [String],
        timeout: TimeInterval
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for label in labels {
                let button = app.buttons[label]
                if button.exists { return button }
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return nil
    }

    @MainActor
    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval)
        -> Bool
    {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isEnabled { return true }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
}
