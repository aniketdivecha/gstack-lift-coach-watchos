import Foundation
import Testing
@testable import WristCoachKit

@Suite("WatchProgramReceiver")
struct WatchProgramReceiverTests {
    private struct FailingStore: ProgramStore {
        enum Failure: Error, Equatable {
            case unavailable
        }

        func programs() async throws -> [Program] { throw Failure.unavailable }
        func program(id: UUID) async throws -> Program? { throw Failure.unavailable }
        func save(_ program: Program) async throws { throw Failure.unavailable }
        func delete(id: UUID) async throws { throw Failure.unavailable }
    }

    @Test("a valid program message is saved")
    func validProgramIsSaved() async throws {
        let store = InMemoryProgramStore()
        let receiver = WatchProgramReceiver(store: store)

        let result = try await receiver.receive(WatchMessage.sendProgram(SamplePrograms.pushA))

        #expect(result == .accepted(SamplePrograms.pushA.id))
        #expect(try await store.programs() == [SamplePrograms.pushA])
    }

    @Test("an invalid program is left out of the store")
    func invalidProgramIsRejected() async throws {
        let store = InMemoryProgramStore()
        let receiver = WatchProgramReceiver(store: store)
        let broken = Program(name: "", exercises: [])
        let message = WatchMessage.sendProgram(broken)

        let result = try await receiver.receive(message)

        #expect(result == .rejected(message.validationIssues))
        #expect(try await store.programs().isEmpty)
    }

    @Test("a newer message version is rejected")
    func newerVersionIsRejected() async throws {
        let store = InMemoryProgramStore()
        let receiver = WatchProgramReceiver(store: store)
        let message = WatchMessage(
            version: WatchMessage.currentVersion + 1,
            kind: .sendProgram,
            program: SamplePrograms.legs
        )

        let result = try await receiver.receive(message)

        #expect(result == .rejected(message.validationIssues))
        #expect(try await store.programs().isEmpty)
    }

    @Test("a request is ignored by the program receiver")
    func requestIsIgnored() async throws {
        let store = InMemoryProgramStore()
        let receiver = WatchProgramReceiver(store: store)

        let result = try await receiver.receive(WatchMessage.requestProgram())

        #expect(result == .ignored(.requestProgram))
        #expect(try await store.programs().isEmpty)
    }

    @Test("a second program lands beside the first")
    func secondProgramIsAdded() async throws {
        let store = InMemoryProgramStore()
        let receiver = WatchProgramReceiver(store: store)

        _ = try await receiver.receive(WatchMessage.sendProgram(SamplePrograms.pushA))
        _ = try await receiver.receive(WatchMessage.sendProgram(SamplePrograms.pullA))

        #expect(try await store.programs().map(\.name) == ["Push A", "Pull A"])
    }

    @Test("a store failure is surfaced to the caller")
    func storeFailurePropagates() async {
        let receiver = WatchProgramReceiver(store: FailingStore())

        do {
            _ = try await receiver.receive(WatchMessage.sendProgram(SamplePrograms.legs))
            Issue.record("Expected the store to fail")
        } catch let error as FailingStore.Failure {
            #expect(error == .unavailable)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
