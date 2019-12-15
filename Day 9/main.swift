import Foundation

let program = intcodeInput()

print("test output:", run(program: program, withInput: [1]))

print("run output:", run(program: program, withInput: [2]))
