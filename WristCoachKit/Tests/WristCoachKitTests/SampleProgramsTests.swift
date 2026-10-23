import Foundation
import Testing
@testable import WristCoachKit

@Suite("SamplePrograms")
struct SampleProgramsTests {
    @Test("every sample program is valid")
    func samplesAreValid() {
        for program in SamplePrograms.all {
            #expect(program.validationIssues.isEmpty, "\(program.name) has issues: \(program.validationIssues)")
        }
    }

    @Test("samples cover push, pull, and legs")
    func samplesCoverMainSplits() {
        #expect(SamplePrograms.all.count == 3)
        #expect(SamplePrograms.all.map(\.name) == ["Push A", "Pull A", "Legs"])
        #expect(SamplePrograms.all.map { $0.exercises.count } == [4, 5, 4])
    }

    @Test("sample ids stay stable across reads")
    func sampleIdsAreStable() {
        #expect(SamplePrograms.pushA.id.uuidString == "A1000000-0000-4000-8000-000000000001")
        #expect(SamplePrograms.pullA.id.uuidString == "A1000000-0000-4000-8000-000000000002")
        #expect(SamplePrograms.legs.id.uuidString == "A1000000-0000-4000-8000-000000000003")
        #expect(SamplePrograms.pushA == SamplePrograms.pushA)
    }

    @Test("exercise ids are unique within each sample")
    func exerciseIdsAreUnique() {
        for program in SamplePrograms.all {
            let ids = program.exercises.map(\.exerciseId)
            #expect(Set(ids).count == ids.count, "\(program.name) repeats an exercise id")
        }
    }

    @Test("sample totals match their targets")
    func sampleTotals() {
        #expect(SamplePrograms.pushA.totalSets == 13)
        #expect(SamplePrograms.pushA.plannedVolume == 10_140)
        #expect(SamplePrograms.pullA.totalSets == 16)
        #expect(SamplePrograms.pullA.plannedVolume == 9_220)
        #expect(SamplePrograms.legs.totalSets == 13)
        #expect(SamplePrograms.legs.plannedVolume == 10_845)
    }
}
