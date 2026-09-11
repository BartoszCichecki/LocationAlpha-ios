//
//  KnownLocationsView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 06/12/2024.
//

import Algorithms
import CoreGPX
import MapKit
import SwiftData
import SwiftUI

struct KnownLocationsView: View {
    @State var date = Date.now

    @State private var showDatePicker = false

    private var latestDate: Date {
        Date.now
    }

    private var earliestDate: Date {
        Date.now - 60 * 60 * 24 * 90
    }

    var body: some View {
        MapView(date: date)
            .contentMargins(.bottom, 72)
            .overlay(alignment: .bottom) {
                HStack {
                    Button {
                        let yesterday = date.yesterday
                        if yesterday >= earliestDate {
                            date = yesterday
                            showDatePicker = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .bold()
                            .padding(8)
                    }
                    .adaptiveGlassEffect()
                    .disabled(date.yesterday < earliestDate)

                    Spacer()

                    Button {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    } label: {
                        Text("\(date.longFormat)")
                            .padding(8)
                    }

                    Spacer()

                    Button {
                        let tomorrow = date.tomorrow
                        if tomorrow <= latestDate {
                            date = tomorrow
                            showDatePicker = false
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .bold()
                            .padding(8)
                    }
                    .adaptiveGlassEffect()
                    .disabled(date.tomorrow > latestDate)
                }
                .padding(8)
                .adaptiveGlassEffect()
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker(selection: $date,
                               in: earliestDate ... latestDate,
                               displayedComponents: [.date])
                    {
                        Text("Date")
                    }
                    .labelsHidden()
                    .datePickerStyle(.graphical)

                    HStack {
                        Button {
                            date = Date.now
                            withAnimation {
                                showDatePicker.toggle()
                            }
                        } label: {
                            Text("Today")
                                .bold()
                        }
                        .adaptiveGlassEffect()
                        .padding(.horizontal, 16)

                        Spacer()

                        Button {
                            withAnimation {
                                showDatePicker.toggle()
                            }
                        } label: {
                            Text("Close")
                                .bold()
                        }
                        .adaptiveGlassEffect()
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .padding(8)
                .presentationDetents([.medium])
            }
            .onAppear {
                if !Calendar.current.isDate(date, inSameDayAs: .now) {
                    date = .now
                }
            }
    }
}

private struct MapView: View {
    @Environment(\.modelContext) private var modelContext

    @Query var knownLocations: [KnownLocation]

    @State var hybrid = false

    private var mapStyle: MapStyle {
        hybrid
            ? .hybrid(elevation: .automatic,
                      pointsOfInterest: .excludingAll,
                      showsTraffic: false)
            : .standard
    }

    init(date: Date) {
        var descriptor = FetchDescriptor<KnownLocation>(predicate: #Predicate {
            $0.timestamp >= date.startOfDay && $0.timestamp <= date.endOfDay
        }, sortBy: [.init(\.timestamp)])
        descriptor.fetchLimit = 2500

        _knownLocations = .init(descriptor)
    }

    var body: some View {
        Map(interactionModes: .init(arrayLiteral: [.pan, .zoom])) {
            ForEach(knownLocations) { location in
                if !location.end {
                    Annotation(coordinate: location.clLocationCoordinate2D) {
                        if location.deviceConnected {
                            Image(systemName: "camera")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .frame(width: 8, height: 8)
                                .background {
                                    Circle()
                                        .foregroundStyle(.accent)
                                        .frame(width: 16, height: 16)
                                }
                        } else {
                            Circle()
                                .foregroundStyle(.accent.opacity(0.5))
                                .frame(width: 16, height: 16)
                        }
                    } label: {
                        EmptyView()
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if knownLocations.filter({ !$0.end }).isEmpty {
                Text("Nothing to show")
                    .font(.callout)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .adaptiveGlassEffect(tint: .accent)
                    .padding(.horizontal, 48)
                    .padding(.top, 16)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button("Map style",
                           systemImage: hybrid ? "map.fill" : "map")
                    {
                        hybrid.toggle()
                    }
                    ShareLink("GPX",
                              item: TransferableData(items: { knownLocations }),
                              preview: SharePreview(TransferableData.filename))
                        .disabled(knownLocations.filter { !$0.end }.isEmpty)
                }
            }
        }
        .contentMargins(.top, knownLocations.isEmpty ? 48 : 0)
        .mapStyle(mapStyle)
    }
}

private struct TransferableData: Transferable {
    static let filename = "locationalpha.gpx"

    private enum TransferError: Error {
        case invalid
    }

    struct TransferableKnownLocation: Sendable {
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let timestamp: Date
        let deviceConnected: Bool
        let end: Bool

        init(_ knownLocation: KnownLocation) {
            latitude = knownLocation.latitude
            longitude = knownLocation.longitude
            altitude = knownLocation.altitude
            timestamp = knownLocation.timestamp
            deviceConnected = knownLocation.deviceConnected
            end = knownLocation.end
        }
    }

    let items: @Sendable () async -> [TransferableKnownLocation]

    init(items: @Sendable @MainActor @escaping () -> [KnownLocation]) {
        self.items = {
            await MainActor.run {
                items().map(TransferableKnownLocation.init)
            }
        }
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .init(exportedAs: "com.topografix.gpx", conformingTo: .xml)) {
            let items = await $0.items()
            let tracks = items.segmented.map {
                let trackPoints = $0.map {
                    let extensions = GPXExtensions()
                    extensions.append(at: nil, contents: ["cammeraConnected": $0.deviceConnected ? "yes" : "no"])

                    let point = GPXTrackPoint(latitude: $0.latitude, longitude: $0.longitude)
                    point.elevation = $0.altitude
                    point.time = $0.timestamp
                    point.extensions = extensions
                    point.fix = .ThreeDimensional
                    return point
                }

                return GPXTrack(segments: [.init(points: trackPoints)])
            }

            let root = GPXRoot(creator: "LocationAlpha")
            root.add(tracks: tracks)

            guard let data = root.gpx().data(using: .utf8) else {
                throw TransferError.invalid
            }

            return data
        }
        .suggestedFileName(TransferableData.filename)
    }
}

private extension [KnownLocation] {
    var segmented: [[KnownLocation]] {
        chunked { !$1.end }
            .map { $0.filter { !$0.end } }
    }
}

private extension [TransferableData.TransferableKnownLocation] {
    var segmented: [[TransferableData.TransferableKnownLocation]] {
        chunked { !$1.end }
            .map { $0.filter { !$0.end } }
    }
}

#Preview("Sample") {
    var dateComponents = DateComponents()
    dateComponents.year = 2025
    dateComponents.month = 9
    dateComponents.day = 30
    dateComponents.timeZone = TimeZone.current
    dateComponents.hour = 12
    dateComponents.minute = 0
    dateComponents.second = 0
    let fromDate = Calendar.current.date(from: dateComponents)!

    dateComponents.day = 2

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KnownLocation.self, configurations: config)
    let context = container.mainContext

    let locations = [
        KnownLocation(latitude: 55.68032286940391, longitude: 12.585115918577609, altitude: 0, timestamp: fromDate, deviceConnected: false),
        KnownLocation(latitude: 55.68087030207199, longitude: 12.584917435110507, altitude: 0, timestamp: fromDate, deviceConnected: false),
        KnownLocation(latitude: 55.681424271809924, longitude: 12.58530815808624, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.681230708074885, longitude: 12.586016261266172, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.681070412381665, longitude: 12.586659991429746, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.68091011603153, longitude: 12.58729835717529, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.68066815803234, longitude: 12.588135206387937, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.68049878654235, longitude: 12.588778936551511, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.680245254684344, longitude: 12.589723420656037, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.68000577073773, longitude: 12.590652434035663, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67978195446555, longitude: 12.591537563010577, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67942977097781, longitude: 12.591150691702907, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67917873002351, longitude: 12.59209482927615, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.678973056715655, longitude: 12.592888763144558, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67866152008671, longitude: 12.59411371419603, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67858590402587, longitude: 12.594178087212388, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67841652351914, longitude: 12.595454818703477, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.6784588687146, longitude: 12.59562648008043, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.6782357439873, longitude: 12.596739794649805, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.678145003709055, longitude: 12.59713139716598, altitude: 0, timestamp: fromDate, deviceConnected: true),
        KnownLocation(latitude: 55.67796654721443, longitude: 12.597539092936243, altitude: 0, timestamp: fromDate, deviceConnected: false),
        KnownLocation(latitude: 55.677857658105914, longitude: 12.597453262247766, altitude: 0, timestamp: fromDate, deviceConnected: false),
        KnownLocation(latitude: 55.677963522521075, longitude: 12.5970992106578, altitude: 0, timestamp: fromDate, deviceConnected: false),
    ]

    for location in locations {
        context.insert(location)
    }

    return TabView(selection: .constant("history")) {
        NavigationStack {
            EmptyView()
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            KnownLocationsView(date: fromDate)
                .modelContainer(container)
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}

#Preview("Empty") {
    TabView(selection: .constant("history")) {
        NavigationStack {
            EmptyView()
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            KnownLocationsView(date: .now)
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}
