import Foundation

struct Orbit {
	var parentID: String
	var childID: String
	
	init(raw: Substring) {
		let ids = raw.components(separatedBy: ")")
		assert(ids.count == 2)
		parentID = ids[0]
		childID = ids[1]
	}
}

final class SpaceObject {
	var id: String
	var parent: SpaceObject?
	
	init(id: String, parent: SpaceObject?) {
		self.id = id
		self.parent = parent
	}
	
	func orbitCount() -> Int {
		guard let parent = parent else { return 0 }
		return parent.orbitCount() + 1
	}
	
	func chain() -> [SpaceObject] {
		Array(sequence(first: self) { $0.parent })
	}
}

extension SpaceObject: Equatable {
	static func == (lhs: SpaceObject, rhs: SpaceObject) -> Bool {
		lhs.id == rhs.id
	}
}

let orbits = input()
	.lines()
	.map(Orbit.init(raw:))

let children = Dictionary(
	grouping: orbits,
	by: { $0.parentID }
).mapValues { $0.map { $0.childID } }

func createChildren(of object: SpaceObject) -> [SpaceObject] {
	children[object.id, default: []].flatMap { id -> [SpaceObject] in
		let child = SpaceObject(id: id, parent: object)
		return createChildren(of: child) + [child]
	}
}

let center = SpaceObject(id: "COM", parent: nil)
let objects = createChildren(of: center)

print("total orbits:", objects.map { $0.orbitCount() }.reduce(0, +))

let myChain = objects.first { $0.id == "YOU" }!.parent!.chain()
let santasChain = objects.first { $0.id == "SAN" }!.parent!.chain()
let common = myChain.first(where: santasChain.contains)!
let distance = myChain.firstIndex(of: common)! + santasChain.firstIndex(of: common)!
print("distance:", distance)
