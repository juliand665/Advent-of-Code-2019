import Foundation

let range = 109165...576723

func isValidPassword(_ password: Int) -> Bool {
	let neighbors = zip(password.digits(), password.digits().dropFirst())
	return true
		&& neighbors.allSatisfy(<=)
		&& neighbors.contains(where: ==)
}

print(range.filter(isValidPassword(_:)).count)

func isStrictlyValidPassword(_ password: Int) -> Bool {
	let digits = password.digits()
	let neighbors = zip(digits, digits.dropFirst())
	return true
		&& neighbors.allSatisfy(<=)
		&& (0...9).contains { digits.count(of: $0) == 2 }
}

print(range.filter(isStrictlyValidPassword(_:)).count)
