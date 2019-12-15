import Foundation

struct Matrix<Element> {
	let width, height: Int
	private(set) var elements: [Element]
	
	init(width: Int, height: Int, repeating element: Element) {
		self.init(
			width: width, height: height,
			elements: Array(repeating: element, count: width * height)
		)
	}
	
	init(width: Int, height: Int, elements: [Element]) {
		self.width = width
		self.height = height
		self.elements = elements
	}
	
	subscript(position: Vector2) -> Element {
		get { elements[position.x + width * position.y] }
		set { elements[position.x + width * position.y] = newValue }
	}
	
	func element(at position: Vector2) -> Element? {
		guard case 0..<width = position.x, case 0..<height = position.y else { return nil }
		return elements[position.x + width * position.y]
	}
	
	func row(at y: Int) -> ArraySlice<Element> {
		elements[width * y ..< width * (y + 1)]
	}
	
	func rows() -> [ArraySlice<Element>] {
		(0..<height).map(row(at:))
	}
	
	func positions() -> [Vector2] {
		(0..<height).flatMap { y in
			(0..<width).map { x in Vector2(x: x, y: y) }
		}
	}
	
	func enumerated() -> [(position: Vector2, element: Element)] {
		Array(zip(positions(), elements))
	}
	
	func transposed() -> Self {
		guard let first = self.element(at: .zero) else { return self }
		
		return Matrix(width: height, height: width, repeating: first) <- { copy in
			for (position, element) in enumerated() {
				copy[Vector2(x: position.y, y: position.x)] = element
			}
		}
	}
	
	func map<T>(_ transform: (Element) throws -> T) rethrows -> Matrix<T> {
		.init(
			width: width, height: height,
			elements: try elements.map(transform)
		)
	}
}

extension Matrix: RandomAccessCollection {
	var startIndex: Vector2 { .zero }
	
	var endIndex: Vector2 { .init(0, height) }
	
	func index(before i: Vector2) -> Vector2 {
		if i.x - 1 >= 0 {
			return Vector2(i.x - 1, i.y)
		} else {
			return Vector2(width - 1, i.y - 1)
		}
	}
	
	func index(after i: Vector2) -> Vector2 {
		if i.x + 1 < width {
			return Vector2(i.x + 1, i.y)
		} else {
			return Vector2(0, i.y + 1)
		}
	}
}
