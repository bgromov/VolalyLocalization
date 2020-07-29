import XCTest

import CRellocTests

var tests = [XCTestCaseEntry]()
tests += CRellocTests.allTests()
tests += VolalyLocalizationTest.allTests()
XCTMain(tests)
