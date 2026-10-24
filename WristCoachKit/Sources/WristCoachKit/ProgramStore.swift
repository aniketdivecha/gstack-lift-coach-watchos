import Foundation

/// Where programs live between launches. The phone owns editing, so the
/// interface stays deliberately small: list, read one, save, delete.
///
/// `throws` is part of the contract even though the in-memory store cannot
/// fail. The file store that comes next can, and callers should not have to
/// change when it arrives.
public protocol ProgramStore: Sendable {
    func programs() async throws -> [Program]
    func program(id: UUID) async throws -> Program?
    func save(_ program: Program) async throws
    func delete(id: UUID) async throws
}

/// Keeps programs in memory for previews, tests, and the first iPhone build.
/// Insertion order is preserved so a list does not reshuffle under the user.
public actor InMemoryProgramStore: ProgramStore {
    private var items: [Program]

    public init(programs: [Program] = []) {
        var seen: Set<UUID> = []
        // Two programs with the same id are the same program. Keep the first.
        self.items = programs.filter { seen.insert($0.id).inserted }
    }

    public func programs() -> [Program] {
        items
    }

    public func program(id: UUID) -> Program? {
        items.first { $0.id == id }
    }

    public func save(_ program: Program) {
        if let index = items.firstIndex(where: { $0.id == program.id }) {
            items[index] = program
        } else {
            items.append(program)
        }
    }

    public func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }
}
