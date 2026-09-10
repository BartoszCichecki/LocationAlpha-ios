//
//  Date+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/05/2025.
//

import Foundation

extension Date {
	var startOfDay: Date {
		Calendar.current.startOfDay(for: self)
	}

	var endOfDay: Date {
		Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)!
	}

	var yesterday: Date {
		Calendar.current.date(byAdding: .day, value: -1, to: self)!
	}

	var tomorrow: Date {
		Calendar.current.date(byAdding: .day, value: 1, to: self)!
	}

	var longFormat: String {
		let df = DateFormatter()
		df.dateStyle = .full
		return df.string(from: self)
	}
}
