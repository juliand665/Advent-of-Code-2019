import Foundation

struct Vector3: Hashable {
	static let zero = Vector3(x: 0, y: 0, z: 0)
	
	var x, y, z: Int
	
	var absolute: Int {
		abs(x) + abs(y) + abs(z)
	}
	
	static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
		lhs <- { $0 += rhs }
	}
	
	static func += (lhs: inout Vector3, rhs: Vector3) {
		lhs.x += rhs.x
		lhs.y += rhs.y
		lhs.z += rhs.z
	}
	
	static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
		lhs <- { $0 -= rhs }
	}
	
	static func -= (lhs: inout Vector3, rhs: Vector3) {
		lhs.x -= rhs.x
		lhs.y -= rhs.y
		lhs.z -= rhs.z
	}
	
	static func * (vec: Vector3, scale: Int) -> Vector3 {
		vec <- { $0 *= scale }
	}
	
	static func * (scale: Int, vec: Vector3) -> Vector3 {
		vec <- { $0 *= scale }
	}
	
	static func *= (vec: inout Vector3, scale: Int) {
		vec.x *= scale
		vec.y *= scale
		vec.z *= scale
	}
	
	func distance(to other: Vector3) -> Int {
		(self - other).absolute
	}
}

extension Vector3 {
	init(_ x: Int, _ y: Int, _ z: Int) {
		self.init(x: x, y: y, z: z)
	}
}

extension Vector3: Parseable {
	init(from parser: inout Parser) {
		parser.consume("<x=")
		x = parser.readInt()
		parser.consume(", y=")
		y = parser.readInt()
		parser.consume(", z=")
		z = parser.readInt()
		parser.consume(">")
	}
}
