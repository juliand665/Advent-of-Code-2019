import Foundation
import AoC_Helpers
import Algorithms
import ArrayBuilder

let memory = Memory(from: input())

var exploration = memory
exploration.runProgram()
let map = Matrix(exploration.outputs
	.map(Character.init(asciiValue:))
	.asString()
	.lines()
	.trimmingSuffix(while: \.isEmpty)
)
print(map)

let start = map.onlyIndex { Direction($0) != nil }!
let startDir = Direction(map[start])!

let intersections = map.positions.filter {
	$0.neighbors.allSatisfy { map.element(at: $0) == "#" }
}
print("intersection score:", intersections.map(\.product).sum()) // 2660

enum Movement: Hashable, CustomStringConvertible {
	case turn(clockwise: Bool)
	case advance(Int)
	
	var description: String {
		switch self {
		case .turn(let clockwise):
			return clockwise ? "R" : "L"
		case .advance(let dist):
			return "\(dist)"
		}
	}
}

var path: [Movement] = []
var position = start
var facing = startDir
while true {
	let options = [true, false]
		.map { ($0, facing.rotated(clockwise: $0)) }
		.filter { map.element(at: position + $1.offset) == "#" }
	guard !options.isEmpty else { break }
	let isClockwise: Bool
	(isClockwise, facing) = options.onlyElement()!
	path.append(.turn(clockwise: isClockwise))
	let distance = position.ray(in: facing)
		.lazy
		.prefix { map.element(at: $0) == "#" }
		.count
	path.append(.advance(distance))
	position += facing.offset * distance
}

struct MovementRoutine {
	var main: [Int]
	var functions: [[Movement]]
}

func encode(_ path: [Movement]) -> String {
	path.map(\.description).joined(separator: ",")
}

let maxLength = 20

func makeRoutine(partLengths: [Int]) -> MovementRoutine? {
	var path = path[...]
	var main: [Int] = []
	var parts: [[Movement]] = []
	for length in partLengths {
		// construct new movement function with given length
		guard let part = path.popFirst(length) else { return nil }
		guard encode(part).count <= maxLength else { return nil }
		main.append(parts.count)
		parts.append(part)
		
		// match known functions against path
		while true {
			let matched = parts.firstIndex { path.starts(with: $0) }
			if let matched {
				path.removeFirst(parts[matched].count)
				main.append(matched)
			} else {
				break
			}
		}
	}
	
	guard path.isEmpty else { return nil }
	guard main.count * 2 - 1 < maxLength else { return nil }
	return .init(main: main, functions: parts)
}

extension Collection {
	func cartesianPower(count: Int) -> any Sequence<[Element]> {
		guard count > 1 else { return self.lazy.map { [$0] } }
		return self.lazy.flatMap { first in cartesianPower(count: count - 1).map { [first] + $0 } }
	}
}

let args = (1...maxLength / 2).cartesianPower(count: 3)
let options = args.compactMap(makeRoutine(partLengths:))
for option in options {
	print("found option:", option)
}

print("path:", path.map(\.description).joined(separator: ","))

let routine = options.first!

let showLiveFeed = false // didn't need this but it's neat

let commandLines: [String] = .build {
	routine.main.map { "A" + $0 }.interspersed(with: ",").asString()
	routine.functions.map(encode)
	showLiveFeed ? "y" : "n"
}
let commandString = commandLines.map { $0 + "\n" }.joined()
let command = commandString.map(\.asciiValue!).map(Int.init)

var execution = memory
execution.data[0] = 2 // execution mode
execution.inputs = .init(command)

if showLiveFeed {
run:
	while true {
		let exitReason = execution.runProgram(exitOnOutput: true)
		switch exitReason {
		case .exitInstruction:
			break run
		case .outputProduced:
			if execution.outputs.ends(with: [10, 10]) { // 2 newlines
				let map = execution.outputs.map(Character.init).asString()
				print(map)
				execution.outputs = []
			}
		case .inputRequired:
			fatalError()
		}
	}
} else {
	execution.runProgram()
}

print("dust collected:", execution.outputs.last!) // 790595
