import Foundation

extension Direction {
	private static let mapping: [Character: Direction] = [
		"U": .up,
		"R": .right,
		"D": .down,
		"L": .left
	]
	
	init(raw: Character) {
		self = Self.mapping[raw]!
	}
}

struct Instruction: Parseable {
	var direction: Direction
	var length: Int
	
	var vector: Vector2 {
		direction.offset * length
	}
	
	init(from parser: inout Parser) {
		direction = .init(raw: parser.consumeNext())
		length = parser.readInt()
	}
}

struct Segment {
	var start: Vector2
	var end: Vector2
	var startStepCount: Int
	
	var minX: Int { min(start.x, end.x) }
	var maxX: Int { max(start.x, end.x) }
	var xRange: ClosedRange<Int> { minX...maxX }
	
	var minY: Int { min(start.y, end.y) }
	var maxY: Int { max(start.y, end.y) }
	var yRange: ClosedRange<Int> { minY...maxY } 
	
	func intersections(with other: Segment) -> [(position: Vector2, stepCount: Int)] {
		guard intersects(other) else { return [] }
		
		let xs = max(minX, other.minX)...min(maxX, other.maxX)
		let ys = max(minY, other.minY)...min(maxY, other.maxY)
		return xs.flatMap { x in
			ys.map { y in
				Vector2(x, y)
			}
		}.map { ($0, steps(to: $0) + other.steps(to: $0)) }
	}
	
	func intersects(_ other: Segment) -> Bool {
		true
			&& xRange.overlaps(other.xRange)
			&& yRange.overlaps(other.yRange)
	}
	
	func steps(to position: Vector2) -> Int {
		startStepCount
			+ abs(position.x - start.x)
			+ abs(position.y - start.y)
	}
}

let instructions = input().lines().map {
	$0.components(separatedBy: ",").map(Instruction.init)
}

let paths: [[Segment]] = instructions.map { path in
	var position = Vector2.zero
	var stepCount = 0
	return path.map { segment in
		let endPosition = position + segment.vector
		defer {
			position = endPosition
			stepCount += segment.length
		}
		return .init(start: position, end: endPosition, startStepCount: stepCount)
	}
}

let path1 = paths[0]
let path2 = paths[1]

let intersections = path1
	.flatMap { path2.flatMap($0.intersections(with:)) }
	.filter { $0.position != .zero }

let closestIntersection = intersections
	.map { $0.position.absolute }
	.min()!
print("closest intersection:", closestIntersection)

let bestIntersection = intersections
	.map { $0.stepCount }
	.min()!
print("best intersection:", bestIntersection)
