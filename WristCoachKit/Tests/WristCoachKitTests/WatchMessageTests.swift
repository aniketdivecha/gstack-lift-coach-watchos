import Foundation
import Testing
@testable import WristCoachKit

@Suite("WatchMessage")
struct WatchMessageTests {
    @Test("a program message carries a valid program")
    func programMessageIsValid() {
        let message = WatchMessage.sendProgram(SamplePrograms.pushA)

        #expect(message.version == WatchMessage.currentVersion)
        #expect(message.kind == .sendProgram)
        #expect(message.program == SamplePrograms.pushA)
        #expect(message.isValid)
    }

    @Test("a request carries its correlation id")
    func requestCarriesId() {
        let id = UUID()
        let message = WatchMessage.requestProgram(requestId: id)

        #expect(message.kind == .requestProgram)
        #expect(message.requestId == id)
        #expect(message.program == nil)
        #expect(message.isValid)
    }

    @Test("an acknowledgement carries its correlation id")
    func acknowledgementCarriesId() {
        let id = UUID()
        let message = WatchMessage.acknowledge(requestId: id)

        #expect(message.kind == .acknowledge)
        #expect(message.requestId == id)
        #expect(message.isValid)
    }

    @Test("a program message needs a program")
    func programMessageNeedsProgram() {
        let message = WatchMessage(kind: .sendProgram)

        #expect(message.validationIssues == [.missingProgram])
    }

    @Test("a program message rejects an invalid program")
    func programMessageRejectsInvalidProgram() {
        let broken = Program(name: "Broken", exercises: [])
        let message = WatchMessage.sendProgram(broken)

        #expect(message.validationIssues.contains(.invalidProgram))
    }

    @Test("a request or acknowledgement needs a request id")
    func requestNeedsId() {
        #expect(WatchMessage(kind: .requestProgram).validationIssues == [.missingRequestId])
        #expect(WatchMessage(kind: .acknowledge).validationIssues == [.missingRequestId])
    }

    @Test("only program messages may carry a program")
    func onlyProgramMessagesCarryPrograms() {
        let message = WatchMessage(kind: .acknowledge, program: SamplePrograms.legs, requestId: UUID())

        #expect(message.validationIssues.contains(.unexpectedProgram))
    }

    @Test("a newer version is rejected")
    func newerVersionIsRejected() {
        let message = WatchMessage(
            version: WatchMessage.currentVersion + 1,
            kind: .requestProgram,
            requestId: UUID()
        )

        #expect(message.validationIssues.contains(.unsupportedVersion(WatchMessage.currentVersion + 1)))
        #expect(!message.isValid)
    }

    @Test("messages round trip through JSON")
    func codableRoundTrip() throws {
        let original = WatchMessage.sendProgram(SamplePrograms.legs)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchMessage.self, from: data)

        #expect(decoded == original)
    }
}
