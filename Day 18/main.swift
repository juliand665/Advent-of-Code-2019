import Foundation
import AoC_Helpers
import Algorithms
import Collections

let map = Matrix(input().lines())
print(map)
let initial = map.onlyIndex(of: "@")!
let keys = map.indexed().filter { $1.isLowercase }.map(\.index).asSet()
let doors = map.indexed().filter { $1.isUppercase }.map(\.index).asSet()

let keysByDoor = doors
	.map { ($0, map.onlyIndex(of: Character(map[$0].lowercased()))!) }
	.asDictionary()

struct Transition {
	var position: Vector2
	var distance: Int
	var keysRequired: Set<Vector2>
}

func explore(from start: Vector2) -> [Transition] {
	var explored: Set<Vector2> = []
	func explore(from position: Vector2, distance: Int, requirements: Set<Vector2>) -> [Transition] {
		guard map[position] != "#" else { return [] }
		guard explored.insert(position).inserted else { return [] }
		
		var requirements = requirements
		if doors.contains(position) {
			requirements.insert(keysByDoor[position]!)
		}
		
		var transitions: [Transition] = []
		if keys.contains(position) {
			transitions.append(.init(position: position, distance: distance, keysRequired: requirements))
		}
		
		for neighbor in position.neighbors {
			transitions.append(contentsOf: explore(
				from: neighbor,
				distance: distance + 1,
				requirements: requirements
			))
		}
		return transitions
	}
	return explore(from: start, distance: 0, requirements: [])
}

let transitions: [Vector2: [Transition]] = chain([initial], keys)
	.lazy
	.map { ($0, explore(from: $0)) }
	.asDictionary()

struct Candidate: Comparable { // TODO: this is essentially identical to Transition actually. worth unifying?
	var position: Vector2
	var distance: Int
	var keysHeld: Set<Vector2>
	
	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.distance < rhs.distance
	}
}

struct State: Hashable {
	var position: Vector2
	var keys: Set<Vector2>
	
	init(_ candidate: Candidate) {
		position = candidate.position
		keys = candidate.keysHeld
	}
}

func shortestPath(from start: Vector2) -> Int? {
	var candidates: Heap<Candidate> = [
		.init(position: start, distance: 0, keysHeld: [])
	]
	var seenStates: Set<State> = []
	while let current = candidates.popMin() {
		guard seenStates.insert(.init(current)).inserted else { continue }
		
		guard current.keysHeld.count < keys.count else {
			return current.distance
		}
		
		let options = transitions[current.position]!
			.lazy
			.filter { !current.keysHeld.contains($0.position) }
			.filter { current.keysHeld.isSuperset(of: $0.keysRequired) }
		let newCandidates = options.map { Candidate(
			position: $0.position,
			distance: current.distance + $0.distance,
			keysHeld: current.keysHeld.union([$0.position])
		) }
		candidates.insert(contentsOf: newCandidates)
	}
	return nil
}

print(shortestPath(from: initial)!) // 5082 too high

// i'm betting part 2 is figuring out the best place (necessarily a key) to start on or something
