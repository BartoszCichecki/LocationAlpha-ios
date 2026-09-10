//
//  Publisher+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/05/2025.
//

import Combine

extension Publisher {
	typealias Pair<T> = (previous: T?, current: T)

	func withPrevious() -> AnyPublisher<Pair<Output>, Failure> {
		scan(nil) {
			Pair(previous: $0?.current, current: $1)
		}
		.compactMap(\.self)
		.eraseToAnyPublisher()
	}
}
