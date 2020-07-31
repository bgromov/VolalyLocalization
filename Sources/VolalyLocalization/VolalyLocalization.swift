import Foundation
import simd
import Combine

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

    residual = estimate_pose(count, p, qc, qv, &x, verbose ? 1 : 0)

    let estimate = Transform(simd_quatd(roll: 0.0, pitch: 0.0, yaw: x[3]), simd_double3(x[..<3]))

    return (fun: residual, x: estimate)
}

public func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform, verbose: Bool = false) -> (fun: Double, x: Transform) {
    assert(points.count == rays.count, "Number of target points and rays should be the same")

    return estimatePose(points: points,
                 rayOrigins: rays.map { $0.origin },
                 rays: rays.map { Transform($0.rotation) * simd_double3(1.0, 0.0, 0.0) },
                 initialGuess: initialGuess,
                 verbose: verbose)
}

public func estimatePoseAsync(points: [simd_double3], rays: [Transform], initialGuess: Transform, verbose: Bool = false) -> Future<(fun: Double, x: Transform), Never>
{
    return Future { promise in
        let res = estimatePose(points: points, rays: rays, initialGuess: initialGuess, verbose: verbose)

        promise(.success(res))
    }
}

public func estimatePoseAsync(points: [simd_double3], rays: [Transform], initialGuess: Transform, verbose: Bool = false, onComplete: @escaping ((fun: Double, x: Transform)) -> Void)
{
    DispatchQueue.global().async {
        let res = estimatePose(points: points, rays: rays, initialGuess: initialGuess, verbose: verbose)
        DispatchQueue.main.async {
            onComplete(res)
        }
    }
}
