import Foundation
import Testing
@testable import WristCoachKit

@Suite("ProgramStore")
struct ProgramStoreTests {
    @Test("a new store is empty")
    func newStoreIsEmpty() async throws {
        let store = InMemoryProgramStore()

        #expect(try await store.programs().isEmpty)
    }

    @Test("saving new programs preserves insertion order")
    func savePreservesInsertionOrder() async throws {
        let store = InMemoryProgramStore()

        try await store.save(SamplePrograms.pushA)
        try await store.save(SamplePrograms.pullA)

        #expect(try await store.programs().map(\.name) == ["Push A", "Pull A"])
    }

    @Test("saving an existing id updates it in place")
    func saveUpdatesInPlace() async throws {
        let store = InMemoryProgramStore(programs: [SamplePrograms.pushA, SamplePrograms.pullA])
        var edited = SamplePrograms.pushA
        edited.name = "Push B"

        try await store.save(edited)

        #expect(try await store.programs().map(\.name) == ["Push B", "Pull A"])
    }

    @Test("deleting a program leaves the others alone")
    func deleteRemovesOnlyTheMatch() async throws {
        let store = InMemoryProgramStore(programs: [SamplePrograms.pushA, SamplePrograms.pullA])

        try await store.delete(id: SamplePrograms.pushA.id)

        #expect(try await store.programs().map(\.name) == ["Pull A"])
    }

    @Test("duplicate ids in the initial list keep the first program")
    func duplicateInitialIdsKeepFirst() async throws {
        var copy = SamplePrograms.legs
        copy.name = "Legs (copy)"
        let store = InMemoryProgramStore(programs: [SamplePrograms.legs, copy])

        #expect(try await store.programs().map(\.name) == ["Legs"])
    }

    @Test("lookup returns the stored program or nil")
    func lookupById() async throws {
        let store = InMemoryProgramStore(programs: [SamplePrograms.legs])

        #expect(try await store.program(id: SamplePrograms.legs.id)?.name == "Legs")
        #expect(try await store.program(id: UUID()) == nil)
    }

    @Test("the in-memory store works through the protocol")
    func worksThroughProtocol() async throws {
        let store: any ProgramStore = InMemoryProgramStore()

        try await store.save(SamplePrograms.legs)

        #expect(try await store.programs().count == 1)
        #expect(try await store.programs().first?.name == "Legs")
    }
}
