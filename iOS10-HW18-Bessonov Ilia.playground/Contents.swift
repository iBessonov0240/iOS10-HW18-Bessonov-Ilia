import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

var nsCondition = NSCondition()
var nsAvailable = false

final class GeneratorThread: Thread {

    private var runCount = 0
    var someSafe = [Chip]()

    override func main() {
        nsCondition.lock()
        nsAvailable = true
        createChip()
        nsCondition.signal()
        nsCondition.unlock()
    }

    func createChip() {
        var timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.someSafe.append(Chip.make())
            self.runCount += 1

            if self.runCount == 10 {
                timer.invalidate()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }
}

final class WorkThread: Thread {

    private var generator = GeneratorThread()

    override func main() {
        nsCondition.lock()

        while !nsAvailable {
            nsCondition.wait()
        }
        generator.start()
        addSodering()
        nsAvailable = false
        nsCondition.unlock()
    }

    func addSodering() {
        if !generator.someSafe.isEmpty {
            let chip = generator.someSafe.removeFirst()
            chip.sodering()
        }
    }
}

let workThread = WorkThread()
workThread.start()
