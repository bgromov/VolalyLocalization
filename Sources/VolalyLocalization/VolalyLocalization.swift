import CRelloc
import Transform

import Foundation
import simd

func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform) -> (Transform, Double) {
    let count = points.count
    let p = points.flatMap { $0.flat }
    let qc = rays[0].origin.flat
    // Unit vector along the X-axis
    let qv = rays.flatMap { ($0 * simd_double3(1.0, 0.0, 0.0)).flat }

    var x: [Double] = initialGuess.origin.flat
    x.append(initialGuess.rotation.rpy.yaw)

    var residual: Double = 0.0

    x.withUnsafeMutableBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: (Double, Double, Double, Double).self, capacity: 1) { ptr in
            residual = estimate_pose(count, p, qc, qv, ptr)
        }
    }

    let estimate = Transform(simd_quatd(roll: 0.0, pitch: 0.0, yaw: x[3]), simd_double3(x[...3]))

    return (estimate, residual)
}
