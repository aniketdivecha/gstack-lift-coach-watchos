import Foundation

/// Stores programs as a JSON array on disk.
///
/// The file is the source of truth, so every call reads it. That keeps two
/// stores pointed at the same file from drifting apart through their own
/// caches. Writes use `.atomic`, because a half-written program list after a
/// crash is worse than no program list.
public actor JSONProgramStore: ProgramStore {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func programs() throws -> [Program] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // No file yet is an empty library, not an error. The first save
            // creates the directory and the file.
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([Program].self, from: data)
    }

    public func program(id: UUID) throws -> Program? {
        try programs().first { $0.id == id }
    }

    public func save(_ program: Program) throws {
        var items = try programs()
        if let index = items.firstIndex(where: { $0.id == program.id }) {
            items[index] = program
        } else {
            items.append(program)
        }
        try write(items)
    }

    public func delete(id: UUID) throws {
        var items = try programs()
        items.removeAll { $0.id == id }
        try write(items)
    }

    private func write(_ items: [Program]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: [.atomic])
    }
}
