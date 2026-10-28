import Foundation
import Testing
@testable import WristCoachKit

@Suite("ProgramPayload")
struct ProgramPayloadTests {
    @Test("a valid program becomes a valid message")
    func validProgramBecomesMessage() throws {
        let message = try ProgramPayload.message(for: SamplePrograms.pushA)

        #expect(message.program == SamplePrograms.pushA)
        #expect(message.kind == .sendProgram)
        #expect(message.isValid)
    }

    @Test("an invalid program never reaches the transport")
    func invalidProgramIsRejected() {
        let broken = Program(name: "", exercises: [])

        do {
            _ = try ProgramPayload.message(for: broken)
            Issue.record("Expected the program to be rejected")
        } catch let error as ProgramPayloadError {
            #expect(error == .invalidProgram(broken.validationIssues))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("the limit includes the envelope, not just the program")
    func limitCoversTheWholeMessage() throws {
        let encoded = try JSONEncoder().encode(WatchMessage.sendProgram(SamplePrograms.pushA))
        let size = encoded.count

        let message = try ProgramPayload.message(for: SamplePrograms.pushA, limit: size)
        #expect(message.program == SamplePrograms.pushA)

        do {
            _ = try ProgramPayload.message(for: SamplePrograms.pushA, limit: size - 1)
            Issue.record("Expected the message to be too large")
        } catch let error as ProgramPayloadError {
            #expect(error == .tooLarge(bytes: size, limit: size - 1))
        }
    }

    @Test("a tiny limit rejects a normal program")
    func tinyLimitRejects() {
        do {
            _ = try ProgramPayload.message(for: SamplePrograms.legs, limit: 16)
            Issue.record("Expected the message to be too large")
        } catch let error as ProgramPayloadError {
            guard case .tooLarge(let bytes, let limit) = error else {
                Issue.record("Expected tooLarge, got \(error)")
                return
            }
            #expect(bytes > 16)
            #expect(limit == 16)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
