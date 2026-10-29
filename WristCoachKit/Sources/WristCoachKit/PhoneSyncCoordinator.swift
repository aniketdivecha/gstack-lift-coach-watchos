import Foundation

public enum PhoneSyncError: Error, Equatable {
    case programNotFound(UUID)
}

/// Sends the program the app selected.
///
/// It does not decide which program is active. That belongs to the app. This
/// type only turns a program into a checked message and hands it to the
/// transport.
public struct PhoneSyncCoordinator: Sendable {
    private let store: any ProgramStore
    private let sender: any WatchMessageSender

    public init(store: any ProgramStore, sender: any WatchMessageSender) {
        self.store = store
        self.sender = sender
    }

    public func sendProgram(id: UUID) async throws -> WatchMessage {
        guard let program = try await store.program(id: id) else {
            throw PhoneSyncError.programNotFound(id)
        }
        return try await send(program)
    }

    public func sendProgram(_ program: Program) async throws -> WatchMessage {
        try await send(program)
    }

    private func send(_ program: Program) async throws -> WatchMessage {
        let message = try ProgramPayload.message(for: program)
        try await sender.send(message)
        return message
    }
}
