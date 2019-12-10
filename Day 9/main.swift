import Foundation

let program = input()
	.lines().first!
	.components(separatedBy: ",")
	.map { Int($0)! }

print("test output:", run(program: program, withInput: [1]))

print("run output:", run(program: program, withInput: [2]))
