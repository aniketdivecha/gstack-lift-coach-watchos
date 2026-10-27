import Foundation

public enum WatchMessageKind: String, Codable, Sendable {
    case sendProgram
    case requestProgram
    case acknowledge
}

public enum WatchMessageIssue: Equatable, Sendable {
    case unsupportedVersion(Int)
    case missingProgram
    case invalidProgram
    case missingRequestId
    case unexpectedProgram

    public var message: String {
        switch self {
        case .unsupportedVersion(let version):
            return "Message version \(version) is newer than this build understands."
        case .missingProgram:
            return "A program message arrived without a program."
        case .invalidProgram:
            return "The program did not pass validation."
        case .missingRequestId:
            return "The message needs a request id."
        case .unexpectedProgram:
            return "Only a program message should carry a program."
        }
    }
}

/// The envelope for everything sent between the phone and the watch.
///
/// Messages are values, not live objects. A receiver decodes one, checks
/// `validationIssues`, and either uses it or ignores it. The version exists so
/// an older watch can say no to a newer phone instead of guessing.
public struct WatchMessage: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let kind: WatchMessageKind
    public let program: Program?
    public let requestId: UUID?

    public init(
        version: Int = WatchMessage.currentVersion,
        kind: WatchMessageKind,
        program: Program? = nil,
        requestId: UUID? = nil
    ) {
        self.version = version
        self.kind = kind
        self.program = program
        self.requestId = requestId
    }

    public static func sendProgram(_ program: Program) -> WatchMessage {
        WatchMessage(kind: .sendProgram, program: program)
    }

    public static func requestProgram(requestId: UUID = UUID()) -> WatchMessage {
        WatchMessage(kind: .requestProgram, requestId: requestId)
    }

    public static func acknowledge(requestId: UUID) -> WatchMessage {
        WatchMessage(kind: .acknowledge, requestId: requestId)
    }

    public var validationIssues: [WatchMessageIssue] {
        var issues: [WatchMessageIssue] = []

        if version < 1 || version > Self.currentVersion {
            issues.append(.unsupportedVersion(version))
        }

        switch kind {
        case .sendProgram:
            guard let program else {
                issues.append(.missingProgram)
                return issues
            }
            if !program.isValid {
                issues.append(.invalidProgram)
            }
        case .requestProgram, .acknowledge:
            if requestId == nil {
                issues.append(.missingRequestId)
            }
            if program != nil {
                issues.append(.unexpectedProgram)
            }
        }

        return issues
    }

    public var isValid: Bool {
        validationIssues.isEmpty
    }
}
