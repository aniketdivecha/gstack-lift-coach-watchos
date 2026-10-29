import Foundation
import Testing
@testable import WristCoachKit

@Suite("PhoneSyncCoordinator")
struct PhoneSyncCoordinatorTests {
    @Test("sends the stored program and returns the message")
    func sendsStoredProgram() async throws {
        let store = InMemoryProgramStore(programs: [SamplePrograms.pushA])
        let transport = RecordingWatchTransport()
        let coordinator = PhoneSyncCoordinator(store: store, sender: transport)

        let message = try await coordinator.sendProgram(id: SamplePrograms.pushA.id)

        #expect(message.program == SamplePrograms.pushA)
        #expect(message.isValid)
        let sent = await transport.sent
        #expect(sent == [message])
    }

    @Test("a missing program throws instead of sending nothing")
    func missingProgramThrows() async {
        let id = UUID()
        let coordinator = PhoneSyncCoordinator(
            store: InMemoryProgramStore(),
            sender: RecordingWatchTransport()
        )

        do {
            _ = try await coordinator.sendProgram(id: id)
            Issue.record("Expected programNotFound")
        } catch let error as PhoneSyncError {
            #expect(error == .programNotFound(id))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("an invalid stored program never reaches the transport")
    func invalidStoredProgramIsRejected() async {
        let broken = Program(name: "", exercises: [])
        let transport = RecordingWatchTransport()
        let coordinator = PhoneSyncCoordinator(
            store: InMemoryProgramStore(programs: [broken]),
            sender: transport
        )

        do {
            _ = try await coordinator.sendProgram(id: broken.id)
            Issue.record("Expected the program to be rejected")
        } catch let error as ProgramPayloadError {
            #expect(error == .invalidProgram(broken.validationIssues))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let sent = await transport.sent
        #expect(sent.isEmpty)
    }

    @Test("a transport failure is not swallowed")
    func transportFailurePropagates() async {
        let transport = RecordingWatchTransport(shouldFail: true)
        let coordinator = PhoneSyncCoordinator(
            store: InMemoryProgramStore(programs: [SamplePrograms.legs]),
            sender: transport
        )

        do {
            _ = try await coordinator.sendProgram(id: SamplePrograms.legs.id)
            Issue.record("Expected sendFailed")
        } catch let error as RecordingWatchTransport.Failure {
            #expect(error == .sendFailed)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("a program can be sent before it is saved")
    func sendsProvidedProgram() async throws {
        let transport = RecordingWatchTransport()
        let coordinator = PhoneSyncCoordinator(store: InMemoryProgramStore(), sender: transport)

        let message = try await coordinator.sendProgram(SamplePrograms.legs)

        #expect(message.program == SamplePrograms.legs)
        let sent = await transport.sent
        #expect(sent == [message])
    }
}
