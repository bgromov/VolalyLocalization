import Foundation
import simd
import Combine

import CRelloc
import Transform

/// Relative localization from motion
final public class RelativeLocalization {
    /// Estimation (optimization) stop strategy.
    /// Corresponds to Dlib stop strategies of BGFS optimization method.
    public enum StopStrategy {
        /// Gradient norm stop strategy.
        ///   - `minNorm`: Stop when the gradient norm is less or equal to this value.
        ///   - `maxIterations`: Stop if this number of iterations exceeded.
        case gradientNorm(minNorm: Double = 1e-5, maxIterations: UInt = 100)
        /// Objective delta stop strategy.
        ///   - `minDelta`: Stop when the objective function changes less or equal to this value.
        ///   - `maxIterations`: Stop if this number of iterations exceeded.
        case objectiveDelta(minDelta: Double = 1e-9, maxIterations: UInt = 0)
    }

    public var verbose: Bool
    public var stopStrategy: StopStrategy

    @Published var estimationResult: (fun: Double, x: Transform)?

    public var publisher: AnyPublisher<(fun: Double, x: Transform)?, Never> {
        get {
            return $estimationResult.eraseToAnyPublisher()
        }
    }

    public init(stopStrategy: StopStrategy = .objectiveDelta(), verbose: Bool = false) {
        self.stopStrategy = stopStrategy
        self.verbose = verbose
    }

    public func reset() {
        estimationResult = nil
    }

    public func estimatePoseAsync(points: [simd_double3], rays: [Transform], initialGuess: Transform? = nil)
    {
        let x0: Transform = initialGuess ?? (estimationResult?.x ?? .identity)

        DispatchQueue.global().async {
            let res = self.estimatePose(points: points, rays: rays, initialGuess: x0)

            DispatchQueue.main.async {
                self.estimationResult = res
            }
        }
    }

    public func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform? = nil)
    {
        let x0: Transform = initialGuess ?? (estimationResult?.x ?? .identity)

        let res = estimatePose(points: points, rays: rays, initialGuess: x0, verbose: verbose)

        DispatchQueue.main.async {
            self.estimationResult = res
        }
    }

    // MARK:- Private interface
    private func estimatePose(points: [simd_double3], rayOrigins: [simd_double3], rays: [simd_double3], initialGuess: Transform) -> (fun: Double, x: Transform) {
        assert(rayOrigins.count == rays.count, "Number of rays and origins should be the same")
        assert(points.count == rays.count, "Number of target points and rays should be the same")

        let count = points.count
        let p = points.flatMap { $0.flat }
        let qc = rayOrigins.flatMap { $0.flat }
        let qv = rays.flatMap { $0.flat }

        var x: [Double] = initialGuess.origin.flat
        x.append(initialGuess.rotation.rpy.yaw)

        var residual: Double = 0.0

        var options = options_t()
        options.verbose = verbose ? 1 : 0

        switch stopStrategy {
        case .gradientNorm(let minNorm, let maxIterations):
            options.stop_strategy = UInt8(GRADIENT_NORM)
            options.stop_threshold = minNorm
            options.max_iter = maxIterations
        case .objectiveDelta(let minDelta, let maxIterations):
            options.stop_strategy = UInt8(OBJECTIVE_DELTA)
            options.stop_threshold = minDelta
            options.max_iter = maxIterations
        }

        residual = estimate_pose(count, p, qc, qv, &x, &options)

        let estimate = Transform(simd_quatd(roll: 0.0, pitch: 0.0, yaw: x[3]), simd_double3(x[..<3]))

        return (fun: residual, x: estimate)
    }

    private func estimatePose(points: [simd_double3], rays: [Transform], initialGuess: Transform, verbose: Bool = false) -> (fun: Double, x: Transform) {
        assert(points.count == rays.count, "Number of target points and rays should be the same")

        return estimatePose(points: points,
                     rayOrigins: rays.map { $0.origin },
                     rays: rays.map { Transform($0.rotation) * simd_double3(1.0, 0.0, 0.0) },
                     initialGuess: initialGuess)
    }

    private func estimatePoseAsync(points: [simd_double3], rays: [Transform], initialGuess: Transform) -> Future<(fun: Double, x: Transform), Never>
    {
        return Future { promise in
            DispatchQueue.global().async {
                let res = self.estimatePose(points: points, rays: rays, initialGuess: initialGuess)

                promise(.success(res))
            }
        }
    }

    private func estimatePoseAsync(points: [simd_double3], rays: [Transform], initialGuess: Transform, onComplete: @escaping ((fun: Double, x: Transform)) -> Void)
    {
        DispatchQueue.global().async {
            let res = self.estimatePose(points: points, rays: rays, initialGuess: initialGuess)
            DispatchQueue.main.async {
                onComplete(res)
            }
        }
    }
}
