import AoC_Helpers

var memory = Memory(data: intcodeInput())
var states = [memory]

extension Memory {
	mutating func printOutputs() {
		print(String(outputs.lazy.map(Character.init)), terminator: "")
		outputs.removeAll()
	}
}

while true {
	memory.runProgram()
	states.append(memory)
	
	memory.printOutputs()
	
	let line = readLine()!
	if line == "undo" {
		states.removeLast()
		memory = states.removeLast()
	} else {
		let input = line + "\n"
		memory.inputs += input.lazy.map { Int($0.asciiValue!) }
	}
}
