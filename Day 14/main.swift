import Foundation
import AoC_Helpers
import SimpleParser
import Algorithms

struct Stack: Parseable {
	var material: Int
	var count: Int
	
	static func * (stack: Self, repeats: Int) -> Self {
		.init(material: stack.material, count: stack.count * repeats)
	}
}

extension Stack {
	init(from parser: inout Parser) {
		count = parser.readInt()
		parser.consume(" ")
		material = getID(parser.consumeRest())
	}
}

extension Stack: CustomStringConvertible {
	var description: String {
		"\(count)x \(material)"
	}
}

struct Step: Parseable {
	var inputs: [Stack]
	var output: Stack
	
	init(from parser: inout Parser) {
		let (i, o) = parser.consumeRest().components(separatedBy: " => ").extract()
		inputs = i.components(separatedBy: ", ").map(Stack.init)
		output = Stack(rawValue: o)
	}
}

let steps = input().lines().map(Step.init)
let byOutput = steps.identified(by: \.output.material)
let ore = getID("ORE")
let fuel = getID("FUEL")
let emptyInv = Array(repeating: 0, count: rawIDs.count)

func oreToProduceFuel(count: Int) -> Int {
	var inventory = emptyInv
	return oreToProduce(Stack(material: fuel, count: count), inventory: &inventory)
}
	
func oreToProduce(_ output: Stack, inventory: inout [Int]) -> Int {
	guard output.material != ore else { return output.count }
	
	let recipe = byOutput[output.material]!
	let existing = min(output.count, inventory[output.material])
	inventory[output.material] -= existing
	let required = output.count - existing
	let repeats = required.ceilOfDivision(by: recipe.output.count)
	let extraOutput = repeats * recipe.output.count - required
	let inputCost = recipe.inputs.map {
		oreToProduce($0 * repeats, inventory: &inventory)
	}.sum()
	inventory[output.material] += extraOutput
	
	return inputCost
}

let orePerFuel = measureTime {
	oreToProduceFuel(count: 1)
}
print(orePerFuel) // 483766

let oreTarget = 1_000_000_000_000
let underestimate = oreTarget / orePerFuel
let fuelProduced = measureTime {
	exponentialSearch(for: oreTarget, from: underestimate) { fuelTarget in
		oreToProduceFuel(count: fuelTarget)
	}
}
print(fuelProduced.exactOrNextBelow) // 3061522
