import AoC_Helpers

let memory = Memory(data: intcodeInput())

func run(_ code: String) {
	var memory = memory
	memory.inputs.append(contentsOf: code.map { Int($0.asciiValue!) })
	memory.runProgram()
	if let damage = memory.outputs.last, damage > 255 {
		print("made it across! damage: \(damage)")
	} else {
		print(String(memory.outputs.map { Character(asciiValue: $0) }), terminator: "")
	}
}

// jump eagerly as soon as you can pass a hole, with fallback if we end up with one right in front
run("""
NOT C J
AND D J
NOT A T
OR T J
WALK

""")

// god i hated this one. there's no way to fully solve it so you just have to try various heuristics until you find one that works. here's a good one:
// jump if  not (A and B and C)  and D              and (E or H)
// i.e. if  there's a hole       you can jump over  and you'll be able to keep moving for at least one step past that hole
run("""
NOT A J
NOT J J
AND B J
AND C J
NOT J J
AND D J
NOT E T
NOT T T
OR H T
AND T J
RUN

""")

