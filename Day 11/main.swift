import Foundation

let program = intcodeInput()

enum Color {
	case black, white
}

func runRobot(startingOn start: Color) -> [Vector2: Color] {
	let memory = Memory(data: program)
	var paintedPanels = [Vector2.zero: start] // technically this would break part 1 if the robot never ends up painting the first panel, but eh…
	var position = Vector2.zero
	var direction = Direction.up
	while true {
		let color = paintedPanels[position] ?? .black
		memory.inputs.append(color == .white ? 1 : 0)
		
		guard let newColor = memory.nextOutput() else { break }
		guard let rotation = memory.nextOutput() else { break }
		
		paintedPanels[position] = newColor == 1 ? .white : .black
		direction.rotate(by: rotation == 1 ? 1 : -1)
		position += direction.offset
	}
	
	return paintedPanels
}

print("panels painted:", runRobot(startingOn: .black).count)

let drawing = runRobot(startingOn: .white)
var output = Matrix(width: 43, height: 6, repeating: "." as Character)
for position in output.positions() {
	if drawing[position] == .white {
		output[position] = "#"
	}
}
print(output.rows().map { String($0) }.joined(separator: "\n"))
