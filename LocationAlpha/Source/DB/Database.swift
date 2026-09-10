//
//  Database.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 21/11/2024.
//

import Foundation
import SwiftData

@MainActor class Database {
    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        container = try ModelContainer(for: KnownDevice.self, KnownLocation.self)
        context = ModelContext(container)
    }

    func read(predicate: Predicate<KnownDevice>?,
              sortDescriptors: SortDescriptor<KnownDevice>...) throws -> [KnownDevice]
    {
        let fetchDescriptor = FetchDescriptor<KnownDevice>(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        return try context.fetch(fetchDescriptor)
    }

    func insert(_ location: KnownLocation, distanceThreshold: Double = 10) throws {
        try context.transaction {
            guard !location.end else {
                context.insert(location)
                return
            }

            var fetchDescriptor = FetchDescriptor<KnownLocation>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            fetchDescriptor.fetchLimit = 1

            let lastLocations = try context.fetch(fetchDescriptor)
            let lastLocation = lastLocations.first

            let distanceFromLast = lastLocation?.distance(from: location) ?? .greatestFiniteMagnitude
            guard distanceFromLast >= distanceThreshold else {
                return
            }

            context.insert(location)
        }
    }

    func upsert(_ device: KnownDevice, updateHandler: (inout KnownDevice) -> Void) throws {
        try context.transaction {
            let devicePeripheralIdentifier = device.identifier
            let fetchDescriptor = FetchDescriptor<KnownDevice>(
                predicate: #Predicate { $0.identifier == devicePeripheralIdentifier }
            )
            let items = try context.fetch(fetchDescriptor)
            if items.isEmpty {
                context.insert(device)
            } else {
                for var item in items {
                    updateHandler(&item)
                    context.insert(item)
                }
            }
        }
    }

    func delete(device: KnownDevice) throws {
        let devicePeripheralIdentifier = device.identifier
        try context.delete(model: KnownDevice.self, where: #Predicate { $0.identifier == devicePeripheralIdentifier })
        guard context.hasChanges else {
            return
        }
        try context.save()
    }

    func cleanUp(locationHistoryLength: LocationHistoryLength) throws {
        guard let locationHistoryLengthDate = Calendar.current.date(byAdding: .day, value: -locationHistoryLength.rawValue, to: .now) else {
            return
        }

        try context.delete(model: KnownLocation.self, where: #Predicate { $0.timestamp < locationHistoryLengthDate })

        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}
