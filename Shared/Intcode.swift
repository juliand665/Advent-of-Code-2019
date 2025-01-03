import Foundation
import Collections
import AoC_Helpers

func intcodeInput() -> [Int] {
    input()
        .lines().first!
        .split(separator: ",")
        .map { Int($0, radix: 10)! }
}

func run(program: [Int], withInput inputs: [Int] = []) -> [Int] {
    var memory = Memory(data: program, inputs: inputs)
    memory.runProgram()
	return .init(memory.outputs)
}

struct Memory {
	var data: [Int]
	var position = 0
	var relativeBase = 0
	
	var inputs: Deque<Int> = []
	var outputs: Deque<Int> = []
	
	init(from input: some StringProtocol) {
		self.init(data: input.split(separator: ",").asInts())
	}
	
	init(data: [Int], inputs: [Int] = []) {
		self.data = data
		self.inputs = .init(inputs)
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
	
	mutating func next() -> Int {
		defer { position += 1 }
		return data[position]
	}
	
	@discardableResult
	mutating func runProgram(exitOnOutput: Bool = false) -> ExitReason {
		while true {
			let (output, exit) = step()
			if let exit {
				return exit
			}
			if exitOnOutput, let output {
				return .outputProduced(output)
			}
		}
	}
	
	@discardableResult
	mutating func step() -> (output: Int?, exit: ExitReason?) {
		let initialPosition = position
		switch Instruction(from: &self) {
		case let .add(lhs, rhs, dest):
			self[dest] = self[lhs] + self[rhs]
		case let .multiply(lhs, rhs, dest):
			self[dest] = self[lhs] * self[rhs]
		case let .input(dest):
			if let input = inputs.popFirst() {
				self[dest] = input
			} else {
				position = initialPosition // reset
				return (nil, .inputRequired)
			}
		case let .output(source):
			let output = self[source]
			outputs.append(output)
			return (output, nil)
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
			return (nil, .exitInstruction)
		}
		return (nil, nil)
	}
	
	mutating func nextOutput() -> Int? {
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
	
	init(from memory: inout Memory) {
		let raw = memory.next()
		let opcode = Opcode(rawValue: raw % 100)!
		var modes = (raw / 100)
			.digits()
			.reversed()
			.map { Parameter.Mode(rawValue: $0)! }[...]
		
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
