import Foundation

struct MotionFixture: Decodable {
    let exerciseId: String
    let sampleRateHz: Double
    let threshold: Double
    let targetReps: Int
    let baselineNoise: Double
    let peakMagnitude: Double
    let durationSeconds: Double
    let peakTimes: [Double]

    struct Sample {
        let t: TimeInterval
        let acceleration: SIMD3<Double>
    }

    var samples: [Sample] {
        let count = Int(durationSeconds * sampleRateHz)
        return (0...count).map { index in
            let t = Double(index) / sampleRateHz
            let isPeak = peakTimes.contains { abs($0 - t) < 0.001 }
            return Sample(
                t: t,
                acceleration: SIMD3<Double>(isPeak ? peakMagnitude : baselineNoise, 0, 0)
            )
        }
    }
}

enum FixtureLoader {
    static func benchPress8Reps() throws -> MotionFixture {
        let bundle = Bundle(for: FixtureBundleToken.self)
        guard let url = bundle.url(forResource: "bench_press_8_reps", withExtension: "json") else {
            throw FixtureError.missingFixture
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(MotionFixture.self, from: data)
    }
}

private final class FixtureBundleToken {}

enum FixtureError: Error {
    case missingFixture
}
