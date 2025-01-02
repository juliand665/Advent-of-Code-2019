import AoC_Helpers
import Collections
import Foundation

let program = intcodeInput()

typealias Packet = (x: Int, y: Int)

final class Computer {
	var address: Int
	var memory: Memory
	var packetBuffer: Deque<Packet> = []
	var wasIdle = false
	
	var isIdle: Bool { wasIdle && packetBuffer.isEmpty }
	
	init(address: Int) {
		self.address = address
		self.memory = .init(data: program, inputs: [address])
	}
	
	func run() -> [(Int, Packet)] {
		if case .inputRequired = memory.step().exit {
			if let (x, y) = packetBuffer.popFirst() {
				memory.inputs = [x, y]
			} else {
				wasIdle = true
				memory.inputs = [-1]
			}
		}
		
		memory.runProgram()
		
		if !memory.outputs.isEmpty {
			wasIdle = false
		}
		
		assert(memory.outputs.count.isMultiple(of: 3))
		defer { memory.outputs.removeAll() }
		return memory.outputs.chunks(ofCount: 3).map { chunk in
			chunk.splat { ($0, ($1, $2)) }
		}
	}
}

let computers = (0..<50).map(Computer.init)
var natPacket: Packet?
var lastDeliveredY: Int?

while true {
	for computer in computers {
		let toSend = computer.run()
		for (dest, packet) in toSend {
			if dest == 255 {
				if natPacket == nil {
					print(packet.y) // part 1
				}
				natPacket = packet
			} else {
				computers[dest].packetBuffer.append(packet)
			}
		}
	}
	if computers.allSatisfy(\.isIdle) {
		if lastDeliveredY == natPacket!.y {
			print(lastDeliveredY!) // part 2
			break
		}
		lastDeliveredY = natPacket!.y
		computers[0].packetBuffer.append(natPacket!)
	}
}
