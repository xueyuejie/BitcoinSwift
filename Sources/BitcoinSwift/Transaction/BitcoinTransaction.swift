//
//  BitcoinTransaction.swift
//  
//
//  Created by xgblin on 2021/12/27.
//

import Foundation
import CryptoSwift

/// Describes a bitcoin transaction, in reply to getdata
public struct BitcoinTransaction {
    /// Transaction data format version (note, this is signed)
    public let version: UInt32
    /// If present, always 0001, and indicates the presence of witness data
    public let flag: UInt16 = 0x00001
    /// Number of Transaction inputs (never zero)
    public var txInCount: UInt8 {
        return UInt8(inputs.count)
    }
    /// A list of 1 or more transaction inputs or sources for coins
    public var inputs: [BitcoinInput]
    /// Number of Transaction outputs
    public var txOutCount: UInt8 {
        return UInt8(outputs.count)
    }
    /// A list of 1 or more transaction outputs or destinations for coins
    public var outputs: [BitcoinOutput]
    /// The block number or timestamp at which this transaction is unlocked
    public let lockTime: UInt32
    /// Signature Hash Helper
    public let sighashHelper: BitcoinSignatureHashHelper
    
    public let zero: Data = Data(repeating: 0, count: 32)
    
    public let one: Data = Data(repeating: 1, count: 1) + Data(repeating: 0, count: 31)
    
    public var txHash: Data {
        return Data(serialized().hash256().reversed())
    }

    public var isSwgWit:Bool {
        for i in 0 ..< inputs.count {
            if inputs[i].isSegwit {
                return true
            }
        }
        return false
    }
    
    public var txID: String {
        return Data(txHash.reversed()).toHexString()
    }
    
    public init(version: UInt32,
                inputs:[BitcoinInput] = [BitcoinInput](),
                outputs:[BitcoinOutput] = [BitcoinOutput](),
                lockTime: UInt32) {
        self.version = version
        self.inputs = inputs
        self.outputs = outputs
        self.lockTime = lockTime
        self.sighashHelper = BitcoinSignatureHashHelper(hashType: .ALL)
    }

    public mutating func addInput(input:BitcoinInput) {
        if let sendInput = input.getInput() {
            inputs.append(sendInput)
        }
    }
    
    public mutating func addOutput(output:BitcoinOutput) {
        outputs.append(output)
    }
    
    public mutating func sign(with keys:[BitcoinKey]) -> BitcoinTransaction?{
        for (i,input) in inputs.enumerated() {
            let key = keys[i]
            if input.isSegwit {
                let varInput = input
                guard let signedInput = varInput.signedInput(transaction: self, inputIndex: i, key: key) else {
                    return nil
                }
                self.inputs[i] = signedInput
            } else {
                guard let signedInput = input.signedInput(transaction: self, inputIndex: i, key: key) else {
                    return nil
                }
                self.inputs[i] = signedInput
//                // Sign transaction hash
//                let sighash: Data = sighashHelper.createSignatureHash(of: self, for: input, inputIndex: i)
//                let signature: Data = try Crypto.sign(sighash, privateKey: key.privateKey!)
//                let pubkey = key.publicKey
//
//                // Create Signature Script
//                let sigWithHashType: Data = signature + [sighashHelper.hashType.uint8]
//                let unlockingScript: Script = try Script()
//                    .appendData(sigWithHashType)
//                    .appendData(pubkey)
//                signedInputs[i] = BitcoinInput(address: input.address,prev_hash: input.prev_hash, index: input.index,value:input.value, signatureScript: unlockingScript.data)
            }
        }
        return BitcoinTransaction(version: self.version,
                                  inputs: inputs,
                                  outputs: self.outputs,
                                  lockTime: self.lockTime)
    }
    
    public func serialized() -> Data {
        var data = Data()
        data.appendUInt32(version)
        if isSwgWit {
            data.appendUInt8(0)
            data.appendUInt8(UInt8(self.flag))
        }
        data.appendVarInt(UInt64(inputs.count))
        inputs.forEach { input in
            data.appendData(input.serialized())
        }
        data.appendVarInt(UInt64(outputs.count))
        outputs.forEach { output in
            data.appendData(output.serialized())
        }
        if isSwgWit {
            inputs.forEach { input in
                if !input.witnessData.data.isEmpty {
                    data.appendVarInt(UInt64(input.witnessData.scriptChunks.count))
                    for i in 0..<input.witnessData.scriptChunks.count {
                        var d:Data = Data()
                        let chunk = input.witnessData.scriptChunks[i]
                        if chunk.isOpcode {
                            data.appendUInt8(chunk.opCode.value)
                        } else {
                            let dataChunk:DataChunk = chunk as! DataChunk
                            d = dataChunk.pushedData
                        }
                        if d.count>0 {
                            data.appendVarInt(UInt64(d.count))
                            data.append(d)
                        }
                    }
                } else {
                    data.appendUInt8(0)
                }
            }
        }
        data.appendUInt32(lockTime)
        return data
    }
}
