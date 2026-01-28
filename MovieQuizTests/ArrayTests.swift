//
//  MovieQuizTests.swift
//  MovieQuizTests
//
//

import Testing

import XCTest
@testable import MovieQuiz

final class ArrayTests: XCTestCase {

    func testGetValueInRange() {
        // Given
        let array = [1, 1, 2, 3, 5]

        // When
        let value = array[safe: 2]

        // Then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 2)
    }

    func testGetValueOutOfRange() {
        // Given
        let array = [1, 1, 2, 3, 5]

        // When
        let value = array[safe: 20]

        // Then
        XCTAssertNil(value)
    }
}
