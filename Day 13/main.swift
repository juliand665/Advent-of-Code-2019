import AoC_Helpers
import Algorithms
import HandyOperators

enum Tile: Int {
	case empty
	case wall
	case block
	case paddle // horizontal
	case ball
	
	var character: Character {
		switch self {
		case .empty:
			return "·"
		case .wall:
			return "█"
		case .block:
			return "#"
		case .paddle:
			return "–"
		case .ball:
			return "o"
		}
	}
}

final class Game: CustomStringConvertible {
	var tiles: [Vector2: Tile] = [:]
	var score = 0
	var memory = Memory(data: code <- { $0[0] = 2 })
	
	var description: String {
		let width = tiles.keys.lazy.map(\.x).max()! + 1
		let height = tiles.keys.lazy.map(\.y).max()! + 1
		let matrix = Matrix(width: width, height: height) { position in
			tiles[position]?.character ?? " "
		}
		return "score: \(score)\n" + matrix.description
	}
	
	init() {}
	
	init(output: [Int]) {
		processOutput(output)
	}
	
	func processOutput(_ output: [Int]) {
		for chunk in output.chunks(ofCount: 3) {
			assert(chunk.count == 3)
			let position = Vector2(chunk.first!, chunk.dropFirst().first!)
			if position == Vector2(-1, 0) {
				score = chunk.last!
			} else {
				tiles[position] = .init(rawValue: chunk.last!)!
			}
		}
	}
	
	func run() {
		while runStep() {}
	}
	
	func cheat() {
		// fill the paddle row entirely with paddles lmao
		let boardStart = memory.data
			.windows(ofCount: 10)
			.enumerated()
			.first { $0.element.allSatisfy { $0 == 0 } }!
			.offset
		let paddle = memory.data.suffix(from: boardStart).firstIndex(of: 3)!
		let paddleRowStart = memory.data.prefix(upTo: paddle).lastIndex(of: 1)! + 1
		let paddleRowEnd = memory.data.suffix(from: paddle).firstIndex(of: 1)!
		for i in paddleRowStart..<paddleRowEnd {
			memory.data[i] = Tile.paddle.rawValue
		}
		
		while true {
			let exitReason = memory.runProgram()
			processOutput(memory.outputs)
			//print(self)
			guard case .inputRequired = exitReason else { return }
			memory.inputs.append(0) // no need to move, ever
		}
	}
	
	func runStep() -> Bool {
		let exitReason = memory.runProgram()
		guard case .inputRequired = exitReason else { return false }
		
		processOutput(memory.outputs)
		memory.outputs = []
		print(self)
		switch readLine()! {
		case "":
			memory.inputs.append(0)
		case "a":
			memory.inputs.append(-1)
		case "d":
			memory.inputs.append(1)
		default:
			print("enter a (left), d (right), or nothing to stay put!")
		}
		return true
	}
}

let code = input().split(separator: ",").asInts()
let output = run(program: code)
let tiles = Game(output: output).tiles
print(tiles.values.count(of: .block), "block tiles")

let game = Game()
//game.run()
measureTime {
	game.cheat()
}
print("final score:", game.score)
