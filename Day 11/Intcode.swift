import Foundation

func intcodeInput() -> [Int] {
	input()
		.lines().first!
		.components(separatedBy: ",")
		.map { Int($0)! }
}

func run(program: [Int], withInput inputs: [Int] = []) -> [Int] {
	(Memory(data: program, inputs: inputs) <- { $0.runProgram() }).outputs
}

final class Memory {
	private var data: [Int]
	var position = 0
	var relativeBase = 0
	
	var inputs: [Int] = []
	var outputs: [Int] = []
	
	init(data: [Int], inputs: [Int] = []) {
		self.data = data
		self.inputs = inputs
	}
	
	subscript(position: Int) -> Int {
		get {
			position < data.count ? data[position] : 0
		}
		set {
			if position >= data.count {
				data.append(contentsOf: repeatElement(0, count: position - data.count + 1))
			}
			data[position] = newValue
		}
	}
	
	subscript(parameter: Parameter) -> Int {
		get { parameter.value(in: self) }
		set { self[parameter.address(in: self)] = newValue }
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
				self[dest] = self[lhs] + self[rhs]
			case let .multiply(lhs, rhs, dest):
				self[dest] = self[lhs] * self[rhs]
			case let .input(dest):
				if let input = inputs.first {
					inputs.removeFirst()
					self[dest] = input
				} else {
					return .inputRequired
				}
			case let .output(source):
				let output = self[source]
				outputs.append(output)
				if exitOnOutput {
					return .outputProduced(output)
				}
			case let .jumpIfTrue(condition, dest):
				if self[condition] != 0 {
					position = self[dest]
				}
			case let .jumpIfFalse(condition, dest):
				if self[condition] == 0 {
					position = self[dest]
				}
			case let .lessThan(lhs, rhs, dest):
				self[dest] = self[lhs] < self[rhs] ? 1 : 0
			case let .equals(lhs, rhs, dest):
				self[dest] = self[lhs] == self[rhs] ? 1 : 0
			case let .adjustRelativeBase(offset):
				relativeBase += self[offset]
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
	
	enum ExitReason {
		case exitInstruction
		case inputRequired
		case outputProduced(Int)
	}
}

enum Instruction {
	case add(Parameter, Parameter, into: Parameter)
	case multiply(Parameter, Parameter, into: Parameter)
	case input(into: Parameter)
	case output(Parameter)
	case jumpIfTrue(if: Parameter, to: Parameter)
	case jumpIfFalse(if: Parameter, to: Parameter)
	case lessThan(Parameter, Parameter, into: Parameter)
	case equals(Parameter, Parameter, into: Parameter)
	case adjustRelativeBase(Parameter)
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
		
		func position() -> Parameter {
			let param = parameter()
			assert(param.mode != .immediate)
			return param
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
		case .adjustRelativeBase:
			self = .adjustRelativeBase(parameter())
		case .exit:
			self = .exit
		}
	}
}

enum Opcode: Int {
	case add = 1
	case multiply = 2
	case input = 3
	case output = 4
	case jumpIfTrue = 5
	case jumpIfFalse = 6
	case lessThan = 7
	case equals = 8
	case adjustRelativeBase = 9
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
		case .relative:
			return memory[memory.relativeBase + value]
		}
	}
	
	func address(in memory: Memory) -> Int {
		switch mode {
		case .position:
			return value
		case .immediate:
			fatalError()
		case .relative:
			return memory.relativeBase + value
		}
	}

	enum Mode: Int {
		case position = 0
		case immediate = 1
		case relative = 2
	}
}
