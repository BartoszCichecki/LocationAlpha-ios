//
//  LogView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 15/11/2024.
//

import OSLog
import SwiftUI

struct LogView: View {
    @Binding var isPresented: Bool

    @State var isLoading = true
    @State var isFilterActive = false
    @State var filter: String = ""
    @State var entries: [LogEntry] = []

    var body: some View {
        VStack {
            if entries.isEmpty {
                ProgressView()
            } else if entries.isEmpty {
                Text("No log entries")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                List(entries.filtered(by: filter, active: isFilterActive)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.category)
                            .font(.caption2)
                            .monospaced()
                            .foregroundStyle(.secondary)
                        Text(entry.description)
                            .font(.caption)
                            .monospaced()
                        Text(entry.date.formatted(date: .numeric, time: .standard))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }.onTapGesture {
                        UIPasteboard.general.string = entry.description
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                .searchable(text: $filter, isPresented: $isFilterActive, prompt: "Filter")
                .listStyle(.plain)
            }
        }
        .navigationTitle("Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isLoading {
                    HStack {
                        ShareLink(item: TransferableData(items: entries),
                                  preview: SharePreview(TransferableData.filename))
                        Button("Refresh", systemImage: "arrow.trianglehead.2.counterclockwise") {
                            isLoading = true
                            isFilterActive = false
                            filter = ""
                            entries = []
                            Task {
                                entries = await loadLog()
                                isLoading = false
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !isLoading {
                    HStack {
                        Button("Close", systemImage: "xmark") {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            isLoading = true
            isFilterActive = false
            filter = ""
            entries = []
            entries = await loadLog()
            isLoading = false
        }
    }

    private func loadLog() async -> [LogEntry] {
        await withCheckedContinuation { continuation in
            guard let store = try? OSLogStore(scope: .currentProcessIdentifier),
                  let entries = try? store.export()
            else {
                continuation.resume(returning: [])
                return
            }

            continuation.resume(returning: entries)
        }
    }
}

private struct TransferableData: Transferable {
    static let filename = "locationalpha_log.txt"

    private enum TransferError: Error {
        case invalid
    }

    let items: [LogEntry]

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .text) {
            let data = $0.items
                .map { "[\($0.date.formatted(date: .numeric, time: .standard))] [\($0.category)] \($0.description)" }
                .joined(separator: "\n")
                .data(using: .utf8)

            guard let data else {
                throw TransferError.invalid
            }

            return data
        }
        .suggestedFileName(TransferableData.filename)
    }
}

private extension [LogEntry] {
    func filtered(by filter: String, active: Bool) -> [LogEntry] {
        self.filter {
            guard active else { return true }
            return $0.description.contains(filter) || $0.category.contains(filter)
        }
    }
}
