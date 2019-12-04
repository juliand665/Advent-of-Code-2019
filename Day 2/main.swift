import Foundation

enum Opcode: Int {
	case add = 1
	case multiply = 2
	case exit = 99
}

func run(_ program: [Int], noun: Int, verb: Int) -> Int {
	run(
		program <- {
			$0[1] = noun
			$0[2] = verb
		}
	).first!
}

func run(_ program: [Int]) -> [Int] {
	var position = 0
	return program <- { memory in
		while true {
			let opcode = Opcode(rawValue: memory[position])!
			switch opcode {
			case .add, .multiply:
				let lhs = memory[position + 1]
				let rhs = memory[position + 2]
				let dest = memory[position + 3]
				let result = (opcode == .add ? (+) : (*))(memory[lhs], memory[rhs])
				memory[dest] = result
				position += 4
			case .exit:
				return
			}
		}
	}
}

let inputProgram = input()
	.lines().first!
	.components(separatedBy: ",")
	.map { Int($0)! }

let result = run(inputProgram, noun: 12, verb: 2)
print("first result:", result)

// "unit tests":
//print(run([1,0,0,0,99])) // [2, 0, 0, 0, 99]
//print(run([2,3,0,3,99])) // [2, 3, 0, 6, 99]
//print(run([2,4,4,5,99,0])) // [2, 4, 4, 5, 99, 9801]
//print(run([1,1,1,4,99,5,6,0,99])) // [30, 1, 1, 4, 2, 5, 6, 0, 99]

let desiredOutput = 19690720
for noun in 0...99 {
	for verb in 0...99 {
		let output = run(inputProgram, noun: noun, verb: verb)
		if output == desiredOutput {
			print("correct input:", 100 * noun + verb)
			// not returning as a sanity check to make sure there's only one match
		}
	}
}
