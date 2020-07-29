import XCTest

import Transform
import simd

@testable import VolalyLocalization

final class VolalyLocalizationTests: XCTestCase {

    func testEstimatePoseSwift() {
        let x: [Double] = [3, 0, 0, -.pi/2]
        let x0 = Transform(simd_quatd(roll: 0, pitch: 0, yaw: x[3]), simd_double3(x: x[0], y: x[1], z: x[2]))

        let (_, new_x) = estimatePose(points: [simd_double3([0, -1, 0])],
                     rayOrigins: [simd_double3([0, 0, 2])],
                     rays: [simd_double3([2, 0, -2])],
                     initialGuess: x0, verbose: true)

        var test_x = new_x.origin.flat
        test_x.append(new_x.rotation.rpy.yaw)

        XCTAssertEqual(test_x, [3, 0, 0, -.pi/2], accuracy: 1e-2)
    }

    static var allTests = [
        ("estimatePoseSwift", testEstimatePoseSwift),
    ]
}
