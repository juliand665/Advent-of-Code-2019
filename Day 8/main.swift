import Foundation

enum Pixel: Int, Hashable, CustomStringConvertible {
	case black
	case white
	case transparent
	
	var description: String {
		switch self {
		case .black:
			return "□"
		case .white:
			return "■"
		case .transparent:
			return "-"
		}
	}
}

struct Layer: CustomStringConvertible {
	var data: [[Pixel]]
	
	var description: String {
		data
			.map { $0.map(String.init(describing:)).joined(separator: " ") }
			.joined(separator: "\n")
	}
}

let digits = input().lines().first!.map { Int(String($0))! }

let width = 25
let height = 6
let size = width * height
let layerCount = digits.count / size

let layers = (0..<layerCount).map { layer in
	Layer(data: (0..<height).map { y in
		let offset = (layer * height + y) * width
		return digits[offset..<offset + width]
			.forceMap(Pixel.init(rawValue:))
	})
}

func count(of pixel: Pixel, in layer: Layer) -> Int {
	layer.data
		.lazy
		.map { $0.count(of: pixel) }
		.reduce(0, +)
}

let checkLayer = layers
	.min { count(of: .black, in: $0) < count(of: .black, in: $1) }!
print(checkLayer)

let checksum = 1
	* count(of: .white, in: checkLayer)
	* count(of: .transparent, in: checkLayer)
print("checksum:", checksum)

let final = layers.reduce(layers.first!) { image, layer in
	Layer(data: zip(image.data, layer.data).map {
		zip($0, $1).map {
			$0 == .transparent ? $1 : $0
		}
	})
}
print(final)
