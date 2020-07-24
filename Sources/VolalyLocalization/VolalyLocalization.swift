import Foundation
import simd

import CRelloc
import Transform

public func estimatePose(points: [simd_double3], rayOrigin: simd_double3, rays: [simd_double3], initialGuess: Transform) -> (fun: Double, x: Transform) {
    let count = points.count
    let p = points.flatMap { $0.flat }
    let qc = rayOrigin.flat
    let qv = rays.flatMap { $0.flat }

    var x: [Double] = initialGuess.origin.flat
    x.append(initialGuess.rotation.rpy.yaw)

    var residual: Double = 0.0

    x.withUnsafeMutableBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: (Double, Double, Double, Double).self, capacity: 1) { ptr in
            residual = estimate_pose(count, p, qc, qv, ptr)
        }
    }

    let estimate = Transform(simd_quatd(roll: 0.0, pitch: 0.0, yaw: x[3]), simd_double3(x[..<3]))

    return (fun: residual, x: estimate)
}

public func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform) -> (fun: Double, x: Transform) {

    return estimatePose(points: points,
                 rayOrigin: rays[0].origin,
                 rays: rays.flatMap { ($0 * simd_double3(1.0, 0.0, 0.0)) },
                 initialGuess: initialGuess)
}
