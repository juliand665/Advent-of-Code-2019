import Foundation
import AoC_Helpers
import Algorithms

let initialDigits = input().map { $0 - "0" }

measureTime {
	let pattern = [0, 1, 0, -1]
	func patternDigit(at index: Int, computingFor baseIndex: Int) -> Int {
		pattern[wrapping: (index + 1) / (baseIndex + 1)]
	}
	
	var digits = initialDigits
	for _ in 0..<100 {
		digits = digits.indices.map { baseIndex in
			abs(digits.enumerated().lazy.map {
				$0.element * patternDigit(at: $0.offset, computingFor: baseIndex)
			}.sum() % 10)
		}
	}
	print(digits.prefix(8).map { "0" + $0 }.asString()) // 37153056
}

measureTime {
	let offset = Int(input().prefix(7))!
	var digits = repeatElement(initialDigits, count: 10_000)
		.joined()
		.dropFirst(offset)
		.asArray()
	for _ in 0..<100 {
		let sums = digits.reductions(0, +)
		let total = sums.last!
		digits = sums.map { abs((total - $0) % 10) }
	}
	print(digits.prefix(8).map { "0" + $0 }.asString()) // 60592199
}

// this is the code that i was initially using before realizing the fact that we were only working in the last <50% meant we were only ever summing up a single range lol, what a troll move
/*
let sumPattern = [-1, 1, 1, -1]
let dist = baseIndex + offset + 1
let indices: [Int] = stride(from: baseIndex, to: digits.count, by: baseIndex + offset + 1) + [digits.count]
let sum = indices
	.lazy
	.chunks(ofCount: 2)
	.filter { $0.count == 2 }
	.enumerated()
	.lazy
	.map { (index: Int, bounds) -> Int in
		let (l, r) = bounds.extract()
		let sum = sums[r] - sums[l]
		return index % 2 == 0 ? sum : -sum
	}
	.sum()
return abs(sum % 10)
*/
