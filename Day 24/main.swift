import AoC_Helpers

typealias Grid = Matrix<Bool>
let grid = Matrix(input().lines()).map { $0 == "#" }
let n = grid.width
let positions = grid.positionMatrix()

func iterate(_ grid: Grid) -> Grid {
	positions.map { position in
		let bugNeighbors = grid.neighbors(of: position).count(of: true)
		return if grid[position] {
			bugNeighbors == 1
		} else {
			(1...2).contains(bugNeighbors)
		}
	}
}

func biodiversity(of grid: Grid) -> Int {
	Int(bits: grid.reversed())
}

let cycled = Cycled.representation(of: sequence(first: grid, next: iterate(_:)))
let firstRepeatedIndex = (0..<cycled.byRound.count).first { i in
	cycled.info(at: i) == cycled.info(at: i + cycled.period)
}!
print(biodiversity(of: cycled.info(at: firstRepeatedIndex)))

let center = Vector2(2, 2)
func neighbors(of position: Vector3, in grids: [Int: Grid]) -> Int {
	let z = position.z
	return Direction.allCases.sum { dir in
		let neighbor = position.xy + dir
		if neighbor == center {
			// go down a level
			let perp = dir.rotated().offset
			return sequence(first: center - dir.offset * 2 - perp * 2 as Vector2) { $0 + perp }
				.prefix(n)
				.count { grids[z + 1]?[$0] == true }
		} else if positions.isInMatrix(neighbor) {
			return grids[z]?[neighbor] == true ? 1 : 0
		} else {
			// go up a level
			return grids[z - 1]?[center + dir] == true ? 1 : 0
		}
	}
}

var grids: [Int: Grid] = [0: grid]
for _ in 1...200 {
	let (minZ, maxZ) = grids.lazy.filter { $1.contains(true) }.map(\.key).minAndMax()!
	grids = (minZ - 1...maxZ + 1).map { z in
		(z, positions.map { pos in
			let neighbors = neighbors(of: Vector3(pos.x, pos.y, z), in: grids)
			return if pos == center {
				false
			} else if grids[z]?[pos] == true {
				neighbors == 1
			} else {
				(1...2).contains(neighbors)
			}
		})
	}.asDictionary()
}
print(grids.values.joined().count(of: true))
