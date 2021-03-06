import Foundation

// The input is hashed using SHA-256.
public struct OpSha256: OpCodeProtocol {
    public var value: UInt8 { return 0xa8 }
    public var name: String { return "OP_SHA256" }

    // input : in
    // output : hash
    public func mainProcess(_ context: ScriptExecutionContext) throws {
        try context.assertStackHeightGreaterThanOrEqual(1)

        let data: Data = context.stack.removeLast()
        let hash: Data = data.sha256()
        context.stack.append(hash)
    }
}
