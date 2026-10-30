import Foundation

public enum WatchReceiveResult: Equatable, Sendable {
    case accepted(UUID)
    case rejected([WatchMessageIssue])
    case ignored(WatchMessageKind)
}

/// Accepts what the phone sends and saves it if it survives validation.
///
/// The watch is allowed to be picky. A malformed or out-of-date message should
/// leave the last good program alone, not replace it with something the app
/// cannot run.
public struct WatchProgramReceiver: Sendable {
    private let store: any ProgramStore

    public init(store: any ProgramStore) {
        self.store = store
    }

    public func receive(_ message: WatchMessage) async throws -> WatchReceiveResult {
        guard message.isValid else {
            return .rejected(message.validationIssues)
        }

        guard message.kind == .sendProgram, let program = message.program else {
            return .ignored(message.kind)
        }

        try await store.save(program)
        return .accepted(program.id)
    }
}
