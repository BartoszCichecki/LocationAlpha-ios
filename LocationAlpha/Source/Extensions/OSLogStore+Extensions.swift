//
//  OSLogStore+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 02/12/2024.
//

import OSLog

struct LogEntry: Identifiable {
    let id = UUID()
    let category: String
    let description: String
    let date: Date
}

extension OSLogStore {
    func export() throws -> [LogEntry] {
        let position = position(date: Date.now.addingTimeInterval(-24 * 3600))
        let entries: [LogEntry] = try getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == "LocationAlpha" }
            .map { LogEntry(category: $0.category, description: $0.composedMessage, date: $0.date) }
            .reversed()
        return entries
    }
}
