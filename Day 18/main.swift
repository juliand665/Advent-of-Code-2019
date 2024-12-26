import Foundation
import AoC_Helpers
import Algorithms
import Collections
import HandyOperators

typealias Key = Vector2

struct Map {
	var grid: Matrix<Character>
	var starts: Set<Vector2>
	var keys: Set<Key>
	var doors: Set<Vector2>
	var keysByDoor: [Vector2: Key]
	
	init(grid: Matrix<Character>) {
		self.grid = grid
		self.starts = grid.indexed().filter { $1 == "@" }.map(\.index).asSet()
		self.keys = grid.indexed().filter { $1.isLowercase }.map(\.index).asSet()
		self.doors = grid.indexed().filter { $1.isUppercase }.map(\.index).asSet()
		
		self.keysByDoor = doors
			.map { ($0, grid.onlyIndex(of: Character(grid[$0].lowercased()))!) }
			.asDictionary()
	}
	
	func findKeyTransitions() -> [Vector2: [Transition]] {
		let poiConnections = findPOIConnections()
		return chain(starts, keys)
			.lazy
			.map { ($0, findKeyTransitions(from: $0, poiConnections: poiConnections)) }
			.asDictionary()
	}
	
	private func findPOIConnections() -> [Vector2: [Vector2: Int]] {
		let pois = Set(chain(chain(starts, keys), doors))
		
		func findConnections(from start: Vector2) -> [Vector2: Int] {
			var explored: Set<Vector2> = []
			var connections: [Vector2: Int] = [:]
			// BFS
			var toExplore: Deque<(position: Vector2, distance: Int)> = [(start, 0)]
			while let (position, distance) = toExplore.popFirst() {
				guard grid[position] != "#" else { continue }
				guard explored.insert(position).inserted else { continue }
				if position != start, pois.contains(position) {
					connections[position] = distance
				} else {
					for neighbor in position.neighbors {
						toExplore.append((neighbor, distance + 1))
					}
				}
			}
			return connections
		}
		
		return pois
			.lazy
			.map { ($0, findConnections(from: $0)) }
			.asDictionary() // distance to other POIs from each POI (start, keys, doors)
	}
	
	private func findKeyTransitions(from start: Vector2, poiConnections: [Vector2: [Vector2: Int]]) -> [Transition] {
		var transitions: [Transition] = []
		var toExplore: Heap<Transition> = [.init(position: start, distance: 0, keysRequired: [], path: [start])]
		while var transition = toExplore.popMin() {
			let position = transition.position
			
			guard !transitions.contains(where: { $0.isBetter(than: transition) }) else { continue } // avoid extraneous transitions in the output
			
			if transition.distance > 0, keys.contains(position) {
				transitions.append(transition)
			} else { // door or start
				if let requiredKey = keysByDoor[position] {
					assert(!transition.keysRequired.contains(requiredKey))
					transition.keysRequired.append(requiredKey)
				}
				
				for (next, distance) in poiConnections[position]! {
					guard !transition.path.contains(next) else { continue }
					
					let nextTransition = transition <- {
						$0.position = next
						$0.distance += distance
						$0.path.append(next)
					}
					guard !transitions.contains(where: { $0.isBetter(than: nextTransition) }) else { continue } // avoid adding hopeless ideas to the heap
					toExplore.insert(nextTransition)
				}
			}
		}
		return transitions
	}
	
	struct Transition: Comparable {
		var position: Vector2
		var distance: Int
		var keysRequired: [Vector2]
		var path: [Vector2]
		
		func isBetter(than other: Self) -> Bool {
			true
			&& position == other.position
			&& distance <= other.distance
			&& keysRequired.allSatisfy(other.keysRequired.contains(_:))
		}
		
		static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.distance < rhs.distance
		}
	}
	
	func shortestPath<Position: Hashable>(from start: Position, transitions: (State<Position>) -> some Sequence<(Position, Int, [Key])>) -> Int? {
		var candidates: Heap<Candidate<Position>> = [
			.init(position: start, distance: 0, keysHeld: [])
		]
		var seenStates: Set<State<Position>> = []
		while let current = candidates.popMin() {
			guard seenStates.insert(.init(current)).inserted else { continue }
			
			guard current.keysHeld.count < keys.count else {
				return current.distance // done: all keys retrieved
			}
			
			let options = transitions(.init(current))
			let newCandidates = options.map { position, distance, keys in Candidate(
				position: position,
				distance: current.distance + distance,
				keysHeld: current.keysHeld.union(keys)
			) }
			candidates.insert(contentsOf: newCandidates)
		}
		return nil
	}
	
	struct Candidate<Position: Hashable>: Comparable {
		var position: Position
		var distance: Int
		var keysHeld: Set<Key>
		
		static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.distance < rhs.distance
		}
	}
	
	struct State<Position: Hashable>: Hashable {
		var position: Position
		var keys: Set<Key>
		
		init(_ candidate: Candidate<Position>) {
			position = candidate.position
			keys = candidate.keysHeld
		}
	}
}

// not super happy with this but it'll do. don't wanna deal with this puzzle anymore lol
do { // don't let general stuff implicitly access these globals
	let grid = Matrix(input().lines())
	print(grid.map { [".": " ", "#": "+"][$0, default: $0] } as Matrix) // more legible
	let start = grid.onlyIndex(of: "@")!
	
	do {
		let map = Map(grid: grid)
		let keyTransitions = map.findKeyTransitions()
		
		measureTime {
			let shortest = map.shortestPath(from: start) { state in
				keyTransitions[state.position]!.lazy.filter {
					state.keys.isSuperset(of: $0.keysRequired)
				}.map { ($0.position, $0.distance, [$0.position]) }
			}
			print(shortest!) // 5068
		}
	}
	
	do {
		let part2Grid = grid <- { grid in
			grid[start] = "#"
			for direction in Direction.allCases {
				grid[start + direction] = "#"
				grid[start + direction + direction.rotated()] = "@"
			}
		}
		let map = Map(grid: part2Grid)
		let keyTransitions = map.findKeyTransitions()
		
		measureTime {
			let shortest = map.shortestPath(from: Array(map.starts)) { state in
				state.position.indices.lazy.flatMap { index in
					keyTransitions[state.position[index]]!.lazy.filter {
						state.keys.isSuperset(of: $0.keysRequired)
					}.map { transition in
						(state.position <- { $0[index] = transition.position }, transition.distance, [transition.position])
					}
				}
			}
			print(shortest!) // 1966, but it took 30 seconds…
		}
	}
}
