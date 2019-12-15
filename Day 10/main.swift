import Foundation

func gcd(_ a: Int, _ b: Int) -> Int {
	func _gcd(_ a: Int, _ b: Int) -> Int {
		b == 0 ? a : _gcd(b, a % b)
	}
	
	return _gcd(abs(a), abs(b))
}

let lines: [[Bool]] = input().lines()
	.prefix { !$0.isEmpty }
	.map { $0.map { $0 == "#" } }
let field = Matrix(
	width: lines.first!.count,
	height: lines.count,
	elements: Array(lines.joined())
)

var visibility = field.map { _ in 0 }
for (position, hasAsteroid) in field.enumerated() where hasAsteroid {
	let directions = field.positions()
		.map { $0 - position }
		.filter { gcd($0.x, $0.y) == 1 }
	
	for direction in directions {
		let lineOfSight = sequence(first: position) { $0 + direction }
			.dropFirst()
		
		for other in lineOfSight {
			guard let hasOther = field.element(at: other) else { break }
			if hasOther {
				visibility[other] += 1
				break
			}
		}
	}
}

let bestCount = visibility.elements.max()!
print("best count:", bestCount)

let stationPosition = visibility.firstIndex(of: bestCount)!
print("station position:", stationPosition)

let offsets = Dictionary(
	grouping: field.enumerated()
		.filter { $0.element == true }
		.map { $0.position - stationPosition }
		.filter { $0 != .zero }
		.sorted { $0.absolute },
	by: { $0 <- ({
		let divisor = gcd($0.x, $0.y)
		$0.x /= divisor
		$0.y /= divisor
	})}
)

let sorted = offsets
	.sorted { (Vector2(-$0.key.y, $0.key.x).angle + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi) } // starting upwards, then clockwise
	.map { $0.value }

// this is totally unnecessary since we already know the 200th asteroid fits within our limit of 340 immediately visible ones
let order = sequence(state: sorted) { (sorted) -> [Vector2]? in
	let first = sorted.map { $0.first! }
	sorted.mapInPlace { $0.removeFirst() }
	sorted.removeAll { $0.isEmpty }
	return first.isEmpty ? nil : first
}.joined()

let offset = order
	.dropFirst(200 - 1)
	.first { _ in true }! // ugh
//print(order.map(String.init(describing:)).joined(separator: "\n"))
print("200th asteroid:", offset + stationPosition)
