import CoreMotion

protocol MotionSource {
    func start(onSample: @escaping (CFAbsoluteTime, SIMD3<Double>) -> Void)
    func stop()
}

final class CMMmotionSource: MotionSource {
    private let motionManager = CMMotionManager()
    private var sampleHandler: ((CFAbsoluteTime, SIMD3<Double>) -> Void)?
    private let motionQueue: OperationQueue

    init(motionQueue: OperationQueue? = nil) {
        self.motionQueue = motionQueue ?? {
            let q = OperationQueue()
            q.name = "com.wristcoach.motion"
            q.maxConcurrentOperationCount = 1
            q.qualityOfService = .userInitiated
            return q
        }()
    }

    func start(onSample: @escaping (CFAbsoluteTime, SIMD3<Double>) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        self.sampleHandler = onSample
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0

        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
            guard let self = self,
                  let m = motion,
                  let handler = self.sampleHandler else {
                return
            }

            let t = CFAbsoluteTimeGetCurrent()
            handler(t, SIMD3<Double>(
                m.userAcceleration.x,
                m.userAcceleration.y,
                m.userAcceleration.z
            ))
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        sampleHandler = nil
    }
}
