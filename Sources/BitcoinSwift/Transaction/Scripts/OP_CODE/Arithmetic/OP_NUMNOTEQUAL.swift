import Foundation

// Returns 1 if the numbers are not equal, 0 otherwise.
public struct OpNumNotEqual: OpCodeProtocol {
    public var value: UInt8 { return 0xe }
    public var name: String { return "OP_NUMNOTEQUAL" }

    // (x1 x2 -- out)
     public func mainProcess(_ context: ScriptExecutionContext) throws {
        try context.assertStackHeightGreaterThanOrEqual(2)

        let x1 = try context.number(at: -2)
        let x2 = try context.number(at: -1)

        context.stack.removeLast()
        context.stack.removeLast()
        context.pushToStack(x1 != x2)
    }
}
