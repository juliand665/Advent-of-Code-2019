import Foundation

infix operator <-: NilCoalescingPrecedence

@discardableResult public func <- <T>(value: T, transform: (inout T) throws -> Void) rethrows -> T {
	var copy = value
	try transform(&copy)
	return copy
}

infix operator ???: NilCoalescingPrecedence

func ??? <Wrapped>(optional: Wrapped?, error: @autoclosure () -> Error) throws -> Wrapped {
	guard let unwrapped = optional else { throw error() }
	return unwrapped
}

prefix operator ^

prefix func ^ <S, T> (keyPath: KeyPath<S, T>) -> (S) -> T {
	{ $0[keyPath: keyPath] }
}

func repeatElement<T>(_ element: T) -> Repeated<T> {
	repeatElement(element, count: .max)
}

extension Sequence {
	func count(where isIncluded: (Element) throws -> Bool) rethrows -> Int {
		try lazy.filter(isIncluded).count
	}
	
	func repeated() -> AnySequence<Element> {
		AnySequence(AnyIterator { self }.joined())
	}
	
	func forceMap<T>(_ transform: (Element) -> T?) -> [T] {
		map { transform($0)! }
	}
}

extension Sequence where Element: Equatable {
	func count(of element: Element) -> Int {
		lazy.filter { $0 == element }.count
	}
}

extension Sequence where Element: Numeric {
	func sum() -> Element {
		reduce(0, +)
	}
}

extension Collection {
	func increasingCombinations() -> AnySequence<(Element, Element)> {
		AnySequence(enumerated()
			.lazy
			.flatMap { zip(repeatElement($0.element), self.dropFirst($0.offset + 1)) }
		)
	}
	
	func allCombinations() -> AnySequence<(Element, Element)> {
		AnySequence(lazy.flatMap { zip(repeatElement($0), self) })
	}
	
	func allOrderings() -> [[Element]] {
		guard !isEmpty else { return [[]] }
		return zip(indices, self).flatMap { i, element in
			((
				Array(self[startIndex..<i])
					+ self[index(after: i)..<endIndex]
			)).allOrderings().map { [element] + $0 }
		}
	}
}

extension Character {
	var firstScalarValue: UInt32 {
		unicodeScalars.first!.value
	}
}

extension Collection {
	func element(at index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension Collection where Index == Int, Element: Collection, Element.Index == Int {
	func element(at position: Vector2) -> Element.Element? {
		element(at: position.y)?.element(at: position.x)
	}
}

extension MutableCollection where Index == Int, Element: MutableCollection, Element.Index == Int {
	/// row-major
	subscript(position: Vector2) -> Element.Element {
		get { self[position.y][position.x] }
		set { self[position.y][position.x] = newValue }
	}
}

protocol ReferenceHashable: AnyObject, Hashable {}

extension ReferenceHashable {
	func hash(into hasher: inout Hasher) {
		withUnsafePointer(to: self) {
			hasher.combine(bytes: UnsafeRawBufferPointer(start: $0, count: MemoryLayout<Self>.size))
		}
	}
}

extension Sequence {
	func sorted<C>(on accessor: (Element) -> C) -> [Element] where C: Comparable {
		self
			.map { ($0, accessor($0)) }
			.sorted { $0.1 < $1.1 }
			.map { $0.0 }
	}
}

extension MutableCollection {
	mutating func mapInPlace(_ transform: (inout Element) -> Void) {
		var index = startIndex
		while index != endIndex {
			transform(&self[index])
			index = self.index(after: index)
		}
	}
}

protocol Rotatable {
	func rotated() -> Self
	func rotated(by diff: Int) -> Self
}

extension Rotatable {
	func rotated() -> Self {
		rotated(by: 1)
	}
}

extension Rotatable where Self: CaseIterable, Self: Equatable, Self.AllCases.Index == Int {
	func rotated(by diff: Int = 1) -> Self {
		let cases = Self.allCases
		return cases[(cases.firstIndex(of: self)! + diff + cases.count) % cases.count]
	}
}

extension Int {
	func digitsFromBack() -> UnfoldSequence<Int, Int> {
		sequence(
			state: self,
			next: ({ num in
				guard num > 0 else { return nil }
				defer { num /= 10 }
				return num % 10
			})
		)
	}
	
	func digits() -> [Int] {
		digitsFromBack().reversed()
	}
}
