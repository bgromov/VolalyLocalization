import XCTest

@testable import CRelloc
@testable import CRelloc_Private

func XCTAssertEqual<T: Collection>(_ expression1: @autoclosure () -> T, _ expression2: @autoclosure () -> T, accuracy: T.Element, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) where T.Element : FloatingPoint {

    XCTAssertEqual(expression1().count, expression2().count, "Arrays of different lengths", file: file, line: line)

    for (e1, e2) in zip(expression1(), expression2()) {
        XCTAssertEqual(e1, e2, accuracy: accuracy, """
            for arrays (\"\(expression1())\") and (\"\(expression2())\")
            """,
                  file: file, line: line)
    }
}

final class CRellocTests: XCTestCase {
    func AssertTransformPoints(from point: [Double], to expected: [Double], with transform: [Double], accuracy: Double, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        assert(point.count == 3, "Point is a three-element array: [x, y, z]")
        assert(transform.count == 4, "Transform is a four-element array: [tx, ty, tz, rotz]")
        assert(expected.count == 3, "Point is a three-element array: [x, y, z]")

        var output = [Double](repeating: .nan, count: 3)

        transform_points(1, point, transform, &output)

        XCTAssertEqual(output, expected, accuracy: accuracy, message(), file: file, line: line)
    }

    func errorFunction(robotLocation: [Double], rayVector: [Double], rayOrigin: [Double], transform: [Double]) -> Double{
        assert(robotLocation.count == 3, "robotLocation is a three-element array: [x, y, z]")
        assert(rayVector.count == 3, "rayVector is a three-element array: [x, y, z]")
        assert(rayOrigin.count == 3, "rayOrigin is a three-element array: [x, y, z]")
        assert(transform.count == 4, "Transform is a four-element array: [tx, ty, tz, rotz]")

        var err: Double = .nan

        error_function(1, robotLocation, rayOrigin, rayVector, transform, &err)

        return err
    }

    func testAngleBetween() {
        // Parallel vectors
        XCTAssertEqual(angle_between([0, 0, 1], [0, 0, 1]),
                       0.0, accuracy: 1e-6)

        // Orthogonal vectors
        XCTAssertEqual(angle_between([1, 0, 0], [0, 0, 1]),
                       .pi / 2.0, accuracy: 1e-6)

        // Non-orthogonal vectors
        XCTAssertNotEqual(angle_between([1, 0, 1], [0, 0, 1]),
                          .pi / 2.0, accuracy: 1e-6)
    }

    func testTransformPoints() {
        // Rotate 45 deg CCW
        AssertTransformPoints(from: [1, 0, 0], to: [0.7071, 0.7071, 0.0],
                        with: [0, 0, 0, .pi / 4],
                        accuracy: 1e-2)

        // Rotate 45 deg CW
        AssertTransformPoints(from: [1, 0, 1], to: [0.7071, -0.7071, 1.0],
                        with: [0, 0, 0, -.pi / 4],
                        accuracy: 1e-2)

        // Rotate 180 deg CW/CCW
        AssertTransformPoints(from: [1, 0, 0], to: [-1, 0, 0],
                        with: [0, 0, 0, -.pi],
                        accuracy: 1e-2)

        // Rotate 90 deg CCW
        AssertTransformPoints(from: [1, 0, 0], to: [0, 1, 0],
                        with: [0, 0, 0, .pi/2],
                        accuracy: 1e-2)

        // Rotate 90 deg CW
        AssertTransformPoints(from: [1, 0, 0], to: [0, -1, 0],
                        with: [0, 0, 0, -.pi/2],
                        accuracy: 1e-2)

        // Translate in +direction on all axes
        AssertTransformPoints(from: [-1, 0, 1], to: [0, 1, 2],
                        with: [1, 1, 1, 0],
                        accuracy: 1e-2)

    }

    func testErrorFunction() {
        // Robot and user share the coordinate frame
        XCTAssertEqual(errorFunction(robotLocation: [2, 0, 0],
                                     rayVector: [2, 0, -2], rayOrigin: [0, 0, 2],
                                     transform: [0, 0, 0, 0]),
                       0.0, accuracy: 1e-2)

        // Robot is looking towards the user and is 1m in front of them
        XCTAssertEqual(errorFunction(robotLocation: [1, 0, 0],
                                     rayVector: [2, 0, -2], rayOrigin: [0, 0, 2],
                                     transform: [3, 0, 0, .pi]),
                       0.0, accuracy: 1e-2)

        // Robot is looking to the right of the user and is 2m in front of them
        XCTAssertEqual(errorFunction(robotLocation: [0, -1, 0],
                                     rayVector: [2, 0, -2], rayOrigin: [0, 0, 2],
                                     transform: [3, 0, 0, -.pi / 2]),
                       0.0, accuracy: 1e-2)

//        XCTAssertEqual(errorFunction(robotLocation: [0, -1, 0],
//                                     rayVector: [2, 0, -2], rayOrigin: [0, 0, 2],
//                                     transform: [1.346, 0.379, -0.272, 1.182]),
//                       0.0, accuracy: 1e-8)
    }

    func testEstimatePose() {
        var x: [Double] = [3, 0, 0, -.pi/2]
        estimate_pose(1, [0, -1, 0], [0, 0, 2], [2, 0, -2], &x, 0)
    }

    static var allTests = [
        ("angleBetween", testAngleBetween),
        ("transformPoints", testTransformPoints),
        ("errorFunction", testErrorFunction),
        ("estimatePose", testEstimatePose),
    ]
}
