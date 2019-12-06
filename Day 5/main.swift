import Foundation

struct Memory {
	var data: [Int]
	var position = 0
	var inputs: [Int] = []
	var outputs: [Int] = []
	
	subscript(position: Int) -> Int {
		get { data[position] }
		set { data[position] = newValue }
	}
	
	mutating func next() -> Int {
		defer { position += 1 }
		return data[position]
	}
	
	mutating func runProgram() {
		while true {
			switch Instruction(from: &self) {
			case let .add(lhs, rhs, dest):
				self[dest] = value(of: lhs) + value(of: rhs)
			case let .multiply(lhs, rhs, dest):
				self[dest] = value(of: lhs) * value(of: rhs)
			case let .input(dest):
				self[dest] = inputs.removeFirst()
			case let .output(source):
				outputs.append(value(of: source))
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
				return
			}
		}
	}
	
	func value(of parameter: Parameter) -> Int {
		parameter.value(in: self)
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
	
	init(from memory: inout Memory) {
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

func run(program: [Int], withInput input: Int) -> [Int] {
	(Memory(data: program, inputs: [input]) <- { $0.runProgram() }).outputs
}

let data = input()
	.lines().first!
	.components(separatedBy: ",")
	.map { Int($0)! }

print(run(program: data, withInput: 1))

print(run(program: data, withInput: 5))
