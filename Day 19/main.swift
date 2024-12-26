import AoC_Helpers
import HandyOperators

let program = intcodeInput()

func isInBeam(_ position: Vector2) -> Bool {
	var memory = Memory(data: program, inputs: [position.x, position.y])
	return memory.nextOutput()! == 1
}

let overview = Matrix(width: 50, height: 50, computing: isInBeam(_:))
print(overview.binaryImage())
print(overview.count(of: true)) // 131

let bottomRight = overview.lastIndex(of: true)!
let gradientEstimate = Double(bottomRight.y - 1) / Double(bottomRight.x) // rounded down to be within the beam for sure
var ranges: [Int: Range<Int>] = [:]
func yRange(atX x: Int) -> Range<Int> {
	if let range = ranges[x] { return range }
	
	let midY = Int(gradientEstimate * Double(x))
	let startY = (0..<midY).partitioningElement { y in
		isInBeam(Vector2(x, y))
	}
	let endY = (midY..<(2 * midY - startY)).partitioningElement { y in
		!isInBeam(Vector2(x, y))
	}
	return startY..<endY <- { ranges[x] = $0 }
}

let shipSize = 100
func canFitShip(maxX: Int) -> Bool {
	let minY = yRange(atX: maxX).lowerBound
	let maxY = minY + shipSize - 1
	return yRange(atX: maxX - shipSize + 1).contains(maxY)
}
let maxX = (0...10_000).partitioningElement(where: canFitShip(maxX:))
let minY = yRange(atX: maxX).lowerBound
let minX = maxX - shipSize + 1
print(minX * 10_000 + minY)
