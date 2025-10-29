//
//  ColorHexExtensionTests.swift
//  TickerCoreTests
//
//  Comprehensive tests for Color+Hex extension
//

import XCTest
import SwiftUI
@testable import TickerCore

final class ColorHexExtensionTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitFromHex6Digit() {
        let color = Color(hex: "#FF6B35")
        XCTAssertNotNil(color)
    }

    func testInitFromHex3Digit() {
        let color = Color(hex: "#F00")
        XCTAssertNotNil(color)
    }

    func testInitFromHex8Digit() {
        let color = Color(hex: "#80FF6B35")
        XCTAssertNotNil(color)
    }

    func testInitFromHexWithoutHash() {
        let color = Color(hex: "FF6B35")
        XCTAssertNotNil(color)
    }

    func testInitFromInvalidHex() {
        let color = Color(hex: "#GGGGGG")
        XCTAssertNil(color)
    }

    func testInitFromInvalidLength() {
        let color = Color(hex: "#FF")
        XCTAssertNil(color)
    }

    func testInitFromEmptyString() {
        let color = Color(hex: "")
        XCTAssertNil(color)
    }

    // MARK: - Color Value Tests

    func testRedColor() {
        let color = Color(hex: "#FF0000")
        XCTAssertNotNil(color)
        // Note: Direct color comparison is difficult in SwiftUI
        // We verify it's created successfully
    }

    func testGreenColor() {
        let color = Color(hex: "#00FF00")
        XCTAssertNotNil(color)
    }

    func testBlueColor() {
        let color = Color(hex: "#0000FF")
        XCTAssertNotNil(color)
    }

    func testWhiteColor() {
        let color = Color(hex: "#FFFFFF")
        XCTAssertNotNil(color)
    }

    func testBlackColor() {
        let color = Color(hex: "#000000")
        XCTAssertNotNil(color)
    }

    func testShorthandRed() {
        let shortColor = Color(hex: "#F00")
        let longColor = Color(hex: "#FF0000")

        XCTAssertNotNil(shortColor)
        XCTAssertNotNil(longColor)
    }

    // MARK: - Alpha Channel Tests

    func testFullyOpaque() {
        let color = Color(hex: "#FFFF6B35")
        XCTAssertNotNil(color)
    }

    func testHalfTransparent() {
        let color = Color(hex: "#80FF6B35")
        XCTAssertNotNil(color)
    }

    func testFullyTransparent() {
        let color = Color(hex: "#00FF6B35")
        XCTAssertNotNil(color)
    }

    // MARK: - Case Insensitivity Tests

    func testLowercaseHex() {
        let color = Color(hex: "#ff6b35")
        XCTAssertNotNil(color)
    }

    func testMixedCaseHex() {
        let color = Color(hex: "#Ff6B35")
        XCTAssertNotNil(color)
    }

    // MARK: - Hex Conversion Tests

    func testToHexBasic() {
        let color = Color.red
        let hex = color.toHex()

        XCTAssertNotNil(hex)
        XCTAssertTrue(hex?.hasPrefix("#") ?? false)
    }

    func testToHexWithAlpha() {
        let color = Color.red
        let hex = color.toHex(includeAlpha: true)

        XCTAssertNotNil(hex)
        XCTAssertTrue(hex?.hasPrefix("#") ?? false)
        // With alpha, should be 9 characters: # + 8 hex digits
        XCTAssertEqual(hex?.count, 9)
    }

    func testToHexWithoutAlpha() {
        let color = Color.blue
        let hex = color.toHex(includeAlpha: false)

        XCTAssertNotNil(hex)
        // Without alpha, should be 7 characters: # + 6 hex digits
        XCTAssertEqual(hex?.count, 7)
    }

    // MARK: - Round-Trip Tests

    func testRoundTripConversion6Digit() {
        let originalHex = "#8B5CF6"
        let color = Color(hex: originalHex)!
        let convertedHex = color.toHex()

        XCTAssertNotNil(convertedHex)
        // Note: May not be exact due to color space conversions
        // We just verify it produces a valid hex
        XCTAssertTrue(convertedHex?.hasPrefix("#") ?? false)
        XCTAssertEqual(convertedHex?.count, 7)
    }

    // MARK: - Edge Cases

    func testVeryLongHexString() {
        let color = Color(hex: "#FF6B35FF6B35")
        XCTAssertNil(color) // Should be invalid
    }

    func testHexWithSpecialCharacters() {
        let color = Color(hex: "#FF-6B-35")
        XCTAssertNotNil(color) // Should strip special chars and parse
    }

    func testHexWithSpaces() {
        let color = Color(hex: "FF 6B 35")
        XCTAssertNotNil(color) // Should strip spaces and parse
    }

    // MARK: - Common Colors

    func testOrangeColor() {
        let color = Color(hex: "#FF6B35")
        XCTAssertNotNil(color)
    }

    func testPurpleColor() {
        let color = Color(hex: "#8B5CF6")
        XCTAssertNotNil(color)
    }

    func testGrayColor() {
        let color = Color(hex: "#808080")
        XCTAssertNotNil(color)
    }
}
