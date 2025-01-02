import AoC_Helpers

enum Step {
	case reverse
	case deal(increment: Int)
	case cut(amount: Int)
	
	init(_ line: some StringProtocol) {
		let int = line.ints(allowSigns: true).onlyElement()
		if line.starts(with: "cut") {
			self = .cut(amount: int!)
		} else {
			assert(line.starts(with: "deal"))
			if let int {
				self = .deal(increment: int)
			} else {
				self = .reverse
			}
		}
	}
}

let steps = input().lines().map(Step.init)

// turns addition into multiplication, multiplication into exponentiation, etc.
// works by breaking down into halves and handling the remainder
func repeatedlyApply<T>(to value: T, repetitions: Int, op: (T, T) -> T) -> T {
	guard repetitions > 1 else {
		assert(repetitions == 1)
		return value
	}
	
	let (half, remainder) = repetitions.quotientAndRemainder(dividingBy: 2)
	let halfExp = repeatedlyApply(to: value, repetitions: half, op: op)
	let fullExp = op(halfExp, halfExp)
	return remainder == 0 ? fullExp : op(fullExp, value)
}

func modExp(_ base: Int, toThe exponent: Int, mod: Int) -> Int {
	repeatedlyApply(to: base, repetitions: exponent) {
		modProduct($0, $1, mod: mod)
	}
}

func modInverse(_ base: Int, mod: Int) -> Int {
	if mod == 10 { // hardcoded this for quick testing against examples (which annoyingly do not have a prime modulus)
		(1..<mod).first { base * $0 % mod == 1 }!
	} else {
		modExp(base, toThe: mod - 2, mod: mod) // fermat's little theorem (modulus is prime)
	}
}

func modProduct(_ a: Int, _ b: Int, mod: Int) -> Int {
	Int(Int128(a) * Int128(b) % Int128(mod))
}

struct Deck: Hashable {
	var first = 0
	var increment = 1
	var count: Int
	
	var last: Int {
		(first - increment + count) %% count
	}
	
	func card(at position: Int) -> Int {
		(first + modProduct(position, increment, mod: count)) %% count
	}
	
	func position(of card: Int) -> Int {
		(card - first) * modInverse(increment, mod: count) %% count
	}
	
	mutating func apply(_ step: Step) {
		switch step {
		case .reverse:
			first = last
			increment = -increment %% count
		case .deal(let dealIncrement):
			// first + dealIncrement * newIncrement = first + increment
			// dealIncrement * newIncrement = increment
			// newIncrement = increment / dealIncrement: need modular inverse
			let inverse = modInverse(dealIncrement, mod: count)
			increment = modProduct(increment, inverse, mod: count)
		case .cut(let amount):
			first = card(at: amount)
		}
	}
	
	func applying(_ steps: [Step]) -> Self {
		steps.reduce(into: self) { $0.apply($1) }
	}
	
	static func + (lhs: Self, rhs: Self) -> Self {
		assert(lhs.count == rhs.count)
		let newIncrement = modProduct(lhs.increment, rhs.increment, mod: lhs.count)
		return .init(
			first: lhs.card(at: rhs.first),
			increment: newIncrement,
			count: lhs.count
		)
	}
}

measureTime {
	let cardCount = 10007
	
	// initial solution (before part 2):
	//func newPosition(of position: Int128, after step: Step) -> Int128 {
	//	switch step {
	//	case .reverse:
	//		cardCount - position - 1
	//	case .deal(let increment):
	//		position * increment % cardCount
	//	case .cut(let amount):
	//		(position - amount + cardCount) % cardCount
	//	}
	//}
	//
	//print(steps.reduce(2019, newPosition(of:after:)))
	
	let deck = Deck(count: cardCount).applying(steps)
	print(deck.position(of: 2019))
}

measureTime {
	let cardCount = 119315717514047
	let repetitions = 101741582076661
	
	let deck = Deck(count: cardCount).applying(steps)
	let final = repeatedlyApply(to: deck, repetitions: repetitions, op: +)
	print(final.card(at: 2020))
}
