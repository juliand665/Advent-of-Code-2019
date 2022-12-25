import Foundation
import AoC_Helpers
import Algorithms

let code = input().split(separator: ",").asInts()
let memory = Memory(data: code)

let directionCommands = Direction.nswe.enumerated().map { ($1, $0 + 1) }.asDictionary()

enum Status: Int {
	case wallHit
	case moved
	case goalFound
}

func move(in direction: Direction) -> Status {
	memory.inputs.append(directionCommands[direction]!)
	return Status(rawValue: memory.nextOutput()!)!
}

var explored: Set<Vector2> = [.zero]
var reachable: Set<Vector2> = []
var goal: Vector2?
func explore(from start: Vector2) {
	reachable.insert(start)
	for direction in Direction.allCases {
		let next = start + direction.offset
		guard explored.insert(next).inserted else { continue }
		switch move(in: direction) {
		case .wallHit:
			break
		case .goalFound:
			assert(goal == nil)
			goal = next
			fallthrough
		case .moved:
			explore(from: next)
			let result = move(in: direction.opposite)
			assert(result != .wallHit)
		}
	}
}
explore(from: .zero)

do {
	var current: Set<Vector2> = [.zero]
	var distance = 0
	while !current.contains(goal!) {
		distance += 1
		current = .init(current.lazy.flatMap(\.neighbors).filter(reachable.contains))
	}
	print(distance) // 216
}

do {
	var current: Set<Vector2> = [goal!]
	var flooded: Set<Vector2> = current
	var time = 0
	while flooded.count < reachable.count {
		time += 1
		current = .init(current.lazy.flatMap(\.neighbors).filter(reachable.contains).filter { !flooded.contains($0) })
		flooded.formUnion(current)
	}
	print(time)
	// 327 too high
}
