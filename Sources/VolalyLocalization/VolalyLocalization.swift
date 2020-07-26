import Foundation
import simd

import CRelloc
import Transform

public func estimatePose(points: [simd_double3], rayOrigins: [simd_double3], rays: [simd_double3], initialGuess: Transform, verbose: Bool = false) -> (fun: Double, x: Transform) {
    assert(rayOrigins.count == rays.count, "Number of rays and origins should be the same")
    assert(points.count == rays.count, "Number of target points and rays should be the same")

    let count = points.count
    let p = points.flatMap { $0.flat }
    let qc = rayOrigins.flatMap { $0.flat }
    let qv = rays.flatMap { $0.flat }

    var x: [Double] = initialGuess.origin.flat
    x.append(initialGuess.rotation.rpy.yaw)

    var residual: Double = 0.0

    x.withUnsafeMutableBufferPointer {
        $0.baseAddress!.withMemoryRebound(to: (Double, Double, Double, Double).self, capacity: 1) { ptr in
            residual = estimate_pose(count, p, qc, qv, ptr, verbose ? 1 : 0)
        }
    }

    let estimate = Transform(simd_quatd(roll: 0.0, pitch: 0.0, yaw: x[3]), simd_double3(x[..<3]))

    return (fun: residual, x: estimate)
}

public func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform, verbose: Bool = false) -> (fun: Double, x: Transform) {
    assert(points.count == rays.count, "Number of target points and rays should be the same")

    return estimatePose(points: points,
                 rayOrigins: rays.map { $0.origin },
                 rays: rays.map { $0 * simd_double3(1.0, 0.0, 0.0) },
                 initialGuess: initialGuess,
                 verbose: verbose)
}
