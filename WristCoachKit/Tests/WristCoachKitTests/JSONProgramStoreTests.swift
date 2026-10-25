import Foundation
import Testing
@testable import WristCoachKit

@Suite("JSONProgramStore")
struct JSONProgramStoreTests {
    private func makeStore() -> (store: JSONProgramStore, directory: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WristCoachKitTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("programs.json")
        return (JSONProgramStore(fileURL: fileURL), directory)
    }

    @Test("a missing file is an empty library")
    func missingFileIsEmpty() async throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try await store.programs().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("programs.json").path))
    }

    @Test("saved programs survive a new store instance")
    func savePersistsAcrossInstances() async throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("programs.json")

        try await store.save(SamplePrograms.pushA)
        let reopened = JSONProgramStore(fileURL: fileURL)

        #expect(try await reopened.programs() == [SamplePrograms.pushA])
    }

    @Test("saving an existing id updates it in place")
    func saveUpdatesInPlace() async throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try await store.save(SamplePrograms.pushA)
        try await store.save(SamplePrograms.pullA)

        var edited = SamplePrograms.pushA
        edited.name = "Push B"
        try await store.save(edited)

        #expect(try await store.programs().map(\.name) == ["Push B", "Pull A"])
    }

    @Test("deleting a program persists the change")
    func deletePersists() async throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("programs.json")
        try await store.save(SamplePrograms.pushA)
        try await store.save(SamplePrograms.pullA)

        try await store.delete(id: SamplePrograms.pushA.id)

        let reopened = JSONProgramStore(fileURL: fileURL)
        #expect(try await reopened.programs().map(\.name) == ["Pull A"])
    }

    @Test("a corrupt file throws instead of returning an empty list")
    func corruptFileThrows() async throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("this is not a program".utf8).write(to: directory.appendingPathComponent("programs.json"))

        do {
            _ = try await store.programs()
            Issue.record("Expected a decoding error")
        } catch {
            // The specific error is JSONDecoder's business, not ours.
        }
    }
}
