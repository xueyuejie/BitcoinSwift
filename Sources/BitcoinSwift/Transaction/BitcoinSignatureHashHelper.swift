//
//  BitcoinSignatureHashHelper.swift
//  
//
//  Created by xgblin on 2021/12/28.
//

import Foundation
let ZeroData256 = Data(hex: "0000000000000000000000000000000000000000000000000000000000000000")!
public struct BitcoinSignatureHashHelper {
    public let zero: Data = Data(repeating: 0, count: 32)
    public let one: Data = Data(repeating: 1, count: 1) + Data(repeating: 0, count: 31)

    public let hashType: SighashType
    public init(hashType: SighashType.BTC) {
        self.hashType = hashType
    }

    /// Create the transaction input to be signed
    public func createSigningInput(of txin: BitcoinInput, from input: BitcoinInput) -> BitcoinInput {
        let subScript = Script(data: input.signatureScript)!
        try! subScript.deleteOccurrences(of: .OP_CODESEPARATOR)
        return BitcoinInput(address:txin.address, prev_hash: txin.prev_hash, index: txin.index,value: txin.value, signatureScript: subScript.data)
    }

    /// Create a blank transaction input
    public func createBlankInput(of txin: BitcoinInput) -> BitcoinInput {
        let sequence: UInt32
        if hashType.isNone || hashType.isSingle {
            sequence = 0
        } else {
            sequence = txin.sequence
        }
        return BitcoinInput(address:txin.address, prev_hash: txin.prev_hash, index: txin.index,value: txin.value, signatureScript: Data(),sequence: sequence)
    }

    /// Create the transaction inputs
    public func createInputs(of tx: BitcoinTransaction, for input: BitcoinInput, inputIndex: Int) -> [BitcoinInput] {
        // If SIGHASH_ANYONECANPAY flag is set, only the input being signed is serialized
        if hashType.isAnyoneCanPay {
            return [createSigningInput(of: tx.inputs[inputIndex], from: input)]
        }

        // Otherwise, all inputs are serialized
        var inputs: [BitcoinInput] = []
        for i in 0..<tx.inputs.count {
            let txin = tx.inputs[i]
            if i == inputIndex {
                inputs.append(createSigningInput(of: txin, from: input))
            } else {
                inputs.append(createBlankInput(of: txin))
            }
        }
        return inputs
    }

    /// Create the transaction outputs
    public func createOutputs(of tx: BitcoinTransaction, inputIndex: Int) -> [BitcoinOutput] {
        if hashType.isNone {
            // Wildcard payee - we can pay anywhere.
            return []
        } else if hashType.isSingle {
            // Single mode assumes we sign an output at the same index as an input.
            // All outputs before the one we need are blanked out. All outputs after are simply removed.
            // Only lock-in the txout payee at same index as txin.
            // This is equivalent to replacing outputs with (i-1) empty outputs and a i-th original one.
            let myOutput = tx.outputs[inputIndex]
            return Array(repeating: BitcoinOutput(value: 0, script: Data()), count: inputIndex) + [myOutput]
        } else {
            return tx.outputs
        }
    }

    /// Create the signature hash of the BTC transaction
    ///
    /// - Parameters:
    ///   - tx: Transaction to be signed
    ///   - utxoOutput: TransactionOutput to be signed
    ///   - inputIndex: The index of the transaction output to be signed
    /// - Returns: The signature hash for the transaction to be signed.
    public func createSignatureHash(of tx: BitcoinTransaction, for input: BitcoinInput, inputIndex: Int) -> Data {
        // If inputIndex is out of bounds, BitcoinABC is returning a 256-bit little-endian 0x01 instead of failing with error.
        guard inputIndex < tx.inputs.count else {
            //  tx.inputs[inputIndex] out of range
            return one
        }

        // Check for invalid use of SIGHASH_SINGLE
        guard !(hashType.isSingle && inputIndex < tx.outputs.count) else {
            //  tx.outputs[inputIndex] out of range
            return one
        }
        var data: Data
        if input.isSegwit {
            data = Data()
            data.appendUInt32(tx.version)
            data.append(self.computeSegWitData(tx: tx, hashType: hashType, inputIndex: inputIndex))
        } else {
            let rawTransaction = BitcoinTransaction(version: tx.version,
                                  inputs: createInputs(of: tx, for: input, inputIndex: inputIndex),
                                  outputs: createOutputs(of: tx, inputIndex: inputIndex),
                                  lockTime: tx.lockTime)
           data  = rawTransaction.serialized()
        }
        // Modified Raw Transaction to be serialized
        data.appendUInt32(hashType.uint32)
        let hash = data.hash256()
        return hash
    }
    
    func computeSegWitData(tx:BitcoinTransaction,hashType:SighashType,inputIndex:Int) -> Data {
        let anyoneCanPay = hashType.rawValue & SIGHASH_ANYONECANPAY != 0
        let sighashSingle = (hashType.rawValue & SIGHASH_OUTPUT_MASK) == SIGHASH_SINGLE
        let sighashNone = (hashType.rawValue & SIGHASH_OUTPUT_MASK) == SIGHASH_NONE
        var payload = Data()
        if anyoneCanPay {
            payload.append(ZeroData256)
        } else {
            var prevouts = Data()
            tx.inputs.forEach { input in
                prevouts.append(input.prev_hash)
                prevouts.appendUInt32(input.index)
            }
            payload.append(prevouts.hash256())
        }
        
        if !anyoneCanPay && !sighashSingle && !sighashNone {
            var sequence = Data()
            tx.inputs.forEach { input in
                sequence.append(Data(hex: "ffffffff"))
            }
            payload.append(sequence.hash256())
        } else {
            payload.append(ZeroData256)
        }
        let input = tx.inputs[inputIndex]
        payload.append(input.prev_hash)
        payload.appendUInt32(input.index)
        payload.append(input.signatureScript)
        payload.appendUInt64(input.value)
        payload.append(Data(hex: "ffffffff"))
        if !sighashSingle && !sighashNone {
            var outputs = Data()
            tx.outputs.forEach { output in
                outputs.append(output.serialized())
            }
            payload.append(outputs.hash256())
        } else if sighashSingle && inputIndex < tx.outputs.count {
            let output = tx.outputs[inputIndex]
            payload.append(output.serialized())
        } else {
            payload.append(ZeroData256)
        }
        payload.appendUInt32(0)
        
        return payload
    }
    
}
