import Foundation

public enum ProgramPayloadError: Error, Equatable {
    case invalidProgram([ProgramValidationIssue])
    case tooLarge(bytes: Int, limit: Int)
}

/// Builds the message that actually leaves the phone.
///
/// WatchConnectivity is happiest with small messages, and the watch should not
/// be the first thing to discover that a program is broken. Validate, encode,
/// then check the size before handing anything to the transport.
public enum ProgramPayload {
    /// 32 KB is far above a real program and far below the point where a
    /// message becomes a delivery problem.
    public static let defaultByteLimit = 32 * 1024

    public static func message(
        for program: Program,
        limit: Int = defaultByteLimit
    ) throws -> WatchMessage {
        let issues = program.validationIssues
        guard issues.isEmpty else {
            throw ProgramPayloadError.invalidProgram(issues)
        }

        let message = WatchMessage.sendProgram(program)
        let data = try JSONEncoder().encode(message)
        guard data.count <= limit else {
            throw ProgramPayloadError.tooLarge(bytes: data.count, limit: limit)
        }
        return message
    }
}
