import Foundation

struct RemoteLogEntry: Identifiable, Hashable, Sendable {
    let id = UUID()
    let date: Date
    let message: String

    var time: String { date.formatted(date: .omitted, time: .standard) }
}
