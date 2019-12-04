import Foundation

func fuelRequired(forMass mass: Int) -> Int {
	max(0, mass / 3 - 2)
}

let masses = input()
	.lines()
	.map { Int($0)! }

let totalFuel = masses
	.map(fuelRequired(forMass:))
	.reduce(0, +)
print("total fuel required:", totalFuel)

func recursiveFuelRequired(forMass mass: Int) -> Int {
	guard mass > 0 else { return 0 }
	
	let fuel = fuelRequired(forMass: mass)
	return fuel + recursiveFuelRequired(forMass: fuel)
}

let recursiveFuel = masses
	.map(recursiveFuelRequired(forMass:))
	.reduce(0, +)
print("recursive fuel required:", recursiveFuel)
