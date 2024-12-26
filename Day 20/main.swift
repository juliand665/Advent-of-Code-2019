import AoC_Helpers

struct Label {
	var name: String
	var position: Vector2
	var isOutside: Bool
}

let grid = Matrix(input().lines())
let center = Vector2(grid.width, grid.height) / 2
let letters = grid.positions { $0.isLetter }
let labels: [Label] = letters.compactMap { start in
	let down = grid.element(at: start + .down)
	let right = grid.element(at: start + .right)
	if let down, down.isLetter {
		let isAfterPoint = grid.element(at: start + .up) == "."
		let isInTopHalf = start.y < center.y
		return Label(
			name: String([grid[start], down]),
			position: start + Vector2(0, isAfterPoint ? -1 : 2),
			isOutside: isAfterPoint != isInTopHalf
		)
	} else if let right, right.isLetter {
		let isAfterPoint = grid.element(at: start + .left) == "."
		let isInLeftHalf = start.x < center.x
		return Label(
			name: String([grid[start], right]),
			position: start + Vector2(isAfterPoint ? -1 : 2, 0),
			isOutside: isAfterPoint != isInLeftHalf
		)
	} else {
		return nil
	}
}
let labelsByName: [String: [Label]] = labels.grouped(by: \.name)
let labelsByPosition: [Vector2: Label] = labels.lazy.map { ($0.position, $0) }.asDictionary()
let start = labelsByName["AA"]!.onlyElement()!.position
let end = labelsByName["ZZ"]!.onlyElement()!.position
let connections: [Vector2: (dest: Vector2, levelChange: Int)] = labelsByName.values.reduce(into: [:]) { connections, labels in
	guard labels.count == 2 else { return }
	let outside = labels.onlyElement { $0.isOutside }!.position
	let inside = labels.onlyElement { !$0.isOutside }!.position
	connections[outside] = (dest: inside, levelChange: -1)
	connections[inside] = (dest: outside, levelChange: +1)
}

measureTime {
	var next = [start]
	var distances: [Vector2: Int] = [:]
	var distance = 0
	while !next.isEmpty {
		for position in next {
			distances[position] = distance
		}
		distance += 1
		next = next
			.lazy
			.flatMap { position -> [Vector2] in
				(connections[position].map { [$0.dest] } ?? []) + position.neighbors
			}
			.filter { grid[$0] == "." }
			.filter { !distances.keys.contains($0) }
	}
	print(distances[end]!)
}

measureTime {
	struct Position: Hashable {
		var position: Vector2
		var level: Int // higher = further inside/smaller
	}
	
	let end = Position(position: end, level: 0)
	
	var next = [Position(position: start, level: 0)]
	var distances: [Position: Int] = [:]
	var distance = 0
	while !next.isEmpty {
		for position in next {
			distances[position] = distance
		}
		if next.contains(end) { break }
		distance += 1
		next = next
			.lazy
			.flatMap { position -> [Position] in
				let neighbors = position.position.neighbors.map { Position(position: $0, level: position.level) }
				if
					let (dest, levelChange) = connections[position.position],
					case let newLevel = position.level + levelChange,
					newLevel >= 0
				{
					return neighbors + [Position(position: dest, level: newLevel)]
				} else {
					return neighbors
				}
			}
			.filter { grid[$0.position] == "." }
			.filter { !distances.keys.contains($0) }
	}
	print(distances[end]!)
}
