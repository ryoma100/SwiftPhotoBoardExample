//
//  SwiftPhotoBoardExampleUITests.swift
//  SwiftPhotoBoardExampleUITests
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import XCTest

final class SwiftPhotoBoardExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        // continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAddEditAndDeleteItem() throws {
        let app = XCUIApplication()
        app.launch()

    }
}
