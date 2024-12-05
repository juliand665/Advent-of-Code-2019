import Foundation
import AoC_Helpers
import Algorithms
import Collections
import HandyOperators

let map = Matrix(input().lines())
print(map.map { [".": " ", "#": "+"][$0, default: $0] } as Matrix) // more legible
let initial = map.onlyIndex(of: "@")!
let keys: Set<Vector2> = map.indexed().filter { $1.isLowercase }.map(\.index).asSet()
let doors: Set<Vector2> = map.indexed().filter { $1.isUppercase }.map(\.index).asSet()

let keysByDoor = doors
	.map { ($0, map.onlyIndex(of: Character(map[$0].lowercased()))!) }
	.asDictionary()

let pois = Set([initial] + keys + doors)
func findConnections(from start: Vector2) -> [Vector2: Int] {
    var explored: Set<Vector2> = []
    var connections: [Vector2: Int] = [:]
    // BFS
    var toExplore: Deque<(position: Vector2, distance: Int)> = [(start, 0)]
    while let (position, distance) = toExplore.popFirst() {
        guard map[position] != "#" else { continue }
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
let poiConnections: [Vector2: [Vector2: Int]] = pois
    .lazy
    .map { ($0, findConnections(from: $0)) }
    .asDictionary() // distance to other POIs from each POI (start, keys, doors)

if false {
    for (start, connections) in poiConnections.sorted(on: { map[$0.key] }) {
        for (target, distance) in connections.sorted(on: { map[$0.key] }) {
            print("\(map[start]) to \(map[target]) in \(distance)")
        }
        print()
    }
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

func explore(from start: Vector2) -> [Transition] {
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

print("finding transitions to keys")
let transitions: [Vector2: [Transition]] = measureTime {
    chain([initial], keys)
        .lazy
        .map { ($0, explore(from: $0)) }
        .asDictionary()
}
// print transitions (for debugging)
if false {
    for (start, transitions) in transitions.sorted(on: { map[$0.key] }) {
        for transition in transitions {
            print("\(map[start]) to \(map[transition.position]) in \(transition.distance) steps with keys \(transition.keysRequired.map { map[$0] }.sorted())")
        }
        print()
    }
}

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
			return current.distance // done: all keys retrieved
		}
		
        let options = transitions[current.position]!.lazy.filter {
            current.keysHeld.isSuperset(of: $0.keysRequired)
        }
		let newCandidates = options.map { Candidate(
			position: $0.position,
			distance: current.distance + $0.distance,
			keysHeld: current.keysHeld.union([$0.position])
		) }
		candidates.insert(contentsOf: newCandidates)
	}
	return nil
}

measureTime {
	print(shortestPath(from: initial)!) // 5068
}
