//
//  CameraLocationData.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import Foundation

struct CameraLocationData {
    private let latitude: Double
    private let longitude: Double
    private let date: Date
    private let timeZone: TimeZone

    init(latitude: Double, longitude: Double, date: Date, timeZone: TimeZone) {
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.timeZone = timeZone
    }

    var data: Data {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.gmt

        let latitude = Int32(latitude * 10_000_000)
        let longitude = Int32(longitude * 10_000_000)

        let year = UInt16(calendar.component(.year, from: date))
        let month = UInt8(calendar.component(.month, from: date))
        let day = UInt8(calendar.component(.day, from: date))

        let hour = UInt8(calendar.component(.hour, from: date))
        let minuts = UInt8(calendar.component(.minute, from: date))
        let seconds = UInt8(calendar.component(.second, from: date))

        let dstOffset = Int16(timeZone.daylightSavingTimeOffset(for: date) / 60)
        let gmtOffset = Int16(timeZone.secondsFromGMT(for: date) / 60) - dstOffset

        return createData(latitude: latitude,
                          longitude: longitude,
                          year: year,
                          month: month,
                          day: day,
                          hour: hour,
                          minutes: minuts,
                          seconds: seconds,
                          gmtOffset: gmtOffset,
                          dstOffset: dstOffset)
    }

    private func createData(latitude: Int32,
                            longitude: Int32,
                            year: UInt16,
                            month: UInt8,
                            day: UInt8,
                            hour: UInt8,
                            minutes: UInt8,
                            seconds: UInt8,
                            gmtOffset: Int16,
                            dstOffset: Int16) -> Data
    {
        var data = Data(count: 0x5F)

        data[0] = 0x00
        data[1] = UInt8(data.count)

        data[2] = 0x08
        data[3] = 0x02
        data[4] = 0xFC

        data[5] = 0x03

        data[8] = 0x10
        data[9] = 0x10
        data[10] = 0x10

        var latitude = latitude
        let latitudeData = Data(bytes: &latitude, count: MemoryLayout<Int32>.size)

        data[11] = latitudeData[3]
        data[12] = latitudeData[2]
        data[13] = latitudeData[1]
        data[14] = latitudeData[0]

        var longitude = longitude
        let longitudeData = Data(bytes: &longitude, count: MemoryLayout<Int32>.size)

        data[15] = longitudeData[3]
        data[16] = longitudeData[2]
        data[17] = longitudeData[1]
        data[18] = longitudeData[0]

        var year = year
        let yearData = Data(bytes: &year, count: MemoryLayout<UInt16>.size)

        data[19] = yearData[1]
        data[20] = yearData[0]

        data[21] = month
        data[22] = day

        data[23] = hour
        data[24] = minutes
        data[25] = seconds

        var gmtOffset = gmtOffset
        let gmtOffsetData = Data(bytes: &gmtOffset, count: MemoryLayout<Int16>.size)

        data[91] = gmtOffsetData[1]
        data[92] = gmtOffsetData[0]

        var dstOffset = dstOffset
        let dstOffsetData = Data(bytes: &dstOffset, count: MemoryLayout<Int16>.size)

        data[93] = dstOffsetData[1]
        data[94] = dstOffsetData[0]

        return data
    }
}
