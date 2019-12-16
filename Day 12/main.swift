import Foundation

let startPositions = input().lines()
	.prefix { !$0.isEmpty }
	.map(Vector3.init)

final class Moon {
	var position: Vector3
	var velocity = Vector3.zero
	
	var energy: Int { position.absolute * velocity.absolute }
	
	init(at position: Vector3) {
		self.position = position
	}
}

var moons = startPositions.map(Moon.init)

for _ in 1...1000 {
	moons.forEach { moon in
		for component in [\Vector3.x, \.y, \.z] {
			let own = moon.position[keyPath: component]
			for otherMoon in moons where otherMoon !== moon {
				let other = otherMoon.position[keyPath: component]
				if other > own {
					moon.velocity[keyPath: component] += 1
				} else if other < own {
					moon.velocity[keyPath: component] -= 1
				}
			}
		}
	}
	
	moons.forEach { $0.position += $0.velocity }
}

let totalEnergy = moons.map { $0.energy }.reduce(0, +)
print("total energy:", totalEnergy)

struct State: Hashable {
	var position: Int
	var velocity = 0
}

let periods: [Int] = [\Vector3.x, \.y, \.z].map { component in
	let initial = startPositions
		.map(^component)
		.map { State(position: $0) }
	var states = initial
	for iteration in 1... {
		states = states.map { $0 <- ({ state in
			state.velocity += states
				.map { ($0.position - state.position).signum() }
				.reduce(0, +)
			state.position += state.velocity
		})}
		
		guard states != initial else {
			return iteration
		}
	}
	fatalError("unreachable")
}
print("individual periods:", periods)
print("common period:", periods.reduce(1, lcm))
