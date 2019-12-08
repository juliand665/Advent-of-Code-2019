import Foundation

final class Memory {
	var data: [Int]
	var position = 0
	var inputs: [Int] = []
	var outputs: [Int] = []
	
	init(data: [Int], inputs: [Int] = []) {
		self.data = data
		self.inputs = inputs
	}
	
	subscript(position: Int) -> Int {
		get { data[position] }
		set { data[position] = newValue }
	}
	
	func next() -> Int {
		defer { position += 1 }
		return data[position]
	}
	
	@discardableResult
	func runProgram(exitOnOutput: Bool = false) -> ExitReason {
		while true {
			switch Instruction(from: self) {
			case let .add(lhs, rhs, dest):
				self[dest] = value(of: lhs) + value(of: rhs)
			case let .multiply(lhs, rhs, dest):
				self[dest] = value(of: lhs) * value(of: rhs)
			case let .input(dest):
				if let input = inputs.first {
					inputs.removeFirst()
					self[dest] = input
				} else {
					return .inputRequired
				}
			case let .output(source):
				let output = value(of: source)
				outputs.append(output)
				if exitOnOutput {
					return .outputProduced(output)
				}
			case let .jumpIfTrue(condition, dest):
				if value(of: condition) != 0 {
					position = value(of: dest)
				}
			case let .jumpIfFalse(condition, dest):
				if value(of: condition) == 0 {
					position = value(of: dest)
				}
			case let .lessThan(lhs, rhs, dest):
				self[dest] = value(of: lhs) < value(of: rhs) ? 1 : 0
			case let .equals(lhs, rhs, dest):
				self[dest] = value(of: lhs) == value(of: rhs) ? 1 : 0
			case .exit:
				return .exitInstruction
			}
		}
	}
	
	func nextOutput() -> Int? {
		switch runProgram(exitOnOutput: true) {
		case .outputProduced(let output):
			return output
		case .exitInstruction:
			return nil
		case .inputRequired:
			fatalError()
		}
	}
	
	func value(of parameter: Parameter) -> Int {
		parameter.value(in: self)
	}
	
	enum ExitReason {
		case exitInstruction
		case inputRequired
		case outputProduced(Int)
	}
}

enum Instruction {
	case add(Parameter, Parameter, into: Int)
	case multiply(Parameter, Parameter, into: Int)
	case input(into: Int)
	case output(Parameter)
	case jumpIfTrue(if: Parameter, to: Parameter)
	case jumpIfFalse(if: Parameter, to: Parameter)
	case lessThan(Parameter, Parameter, into: Int)
	case equals(Parameter, Parameter, into: Int)
	case exit
	
	init(from memory: Memory) {
		let raw = memory.next()
		let opcode = Opcode(rawValue: raw % 100)!
		var modes = (raw / 100)
			.digitsFromBack()
			.forceMap(Parameter.Mode.init(rawValue:))[...]
		
		func parameter() -> Parameter {
			return Parameter(
				value: memory.next(),
				mode: modes.popFirst() ?? .position
			)
		}
		
		func position() -> Int {
			let param = parameter()
			assert(param.mode == .position)
			return param.value
		}
		
		switch opcode {
		case .add:
			self = .add(parameter(), parameter(), into: position())
		case .multiply:
			self = .multiply(parameter(), parameter(), into: position())
		case .input:
			self = .input(into: position())
		case .output:
			self = .output(parameter())
		case .jumpIfTrue:
			self = .jumpIfTrue(if: parameter(), to: parameter())
		case .jumpIfFalse:
			self = .jumpIfFalse(if: parameter(), to: parameter())
		case .lessThan:
			self = .lessThan(parameter(), parameter(), into: position())
		case .equals:
			self = .equals(parameter(), parameter(), into: position())
		case .exit:
			self = .exit
		}
	}
}

enum Opcode: Int {
	case add = 1
	case multiply
	case input
	case output
	case jumpIfTrue
	case jumpIfFalse
	case lessThan
	case equals
	case exit = 99
}

struct Parameter {
	var value: Int
	var mode: Mode
	
	func value(in memory: Memory) -> Int {
		switch mode {
		case .position:
			return memory[value]
		case .immediate:
			return value
		}
	}

	enum Mode: Int {
		case position = 0
		case immediate = 1
	}
}

func run(program: [Int], withInput inputs: [Int]) -> [Int] {
	(Memory(data: program, inputs: inputs) <- { $0.runProgram() }).outputs
}

let program = input()
	.lines().first!
	.components(separatedBy: ",")
	.map { Int($0)! }

func signal(forInput inputs: [Int], program: [Int]) -> Int {
	inputs.reduce(0) { run(program: program, withInput: [$1, $0]).first! }
}

let best = 
(0..<5)
	.allOrderings()
	.map { signal(forInput: $0, program: program) }
	.max()!
print(best)

func feedbackSignal(forInput inputs: [Int], program: [Int]) -> Int {
	let memories = inputs.map { Memory(data: program, inputs: [$0]) }
	var output = 0
	for memory in repeatElement(memories).lazy.joined() {
		memory.inputs.append(output)
		if let next = memory.nextOutput() {
			output = next
		} else {
			return output
		}
	}
	fatalError()
}

let bestWithFeedback = (5...9)
	.allOrderings()
	.map { feedbackSignal(forInput: $0, program: program) }
	.max()!
print(bestWithFeedback)
