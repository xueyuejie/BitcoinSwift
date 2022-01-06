//
//  BitcoinPublicKey.swift
//  
//
//  Created by xgblin on 2021/12/28.
//

import Foundation
import CSecp256k1

public struct BitcoinPublicKey {
    public let data: Data
    public var pubKeyHash: Data {
        return data.hash160()!
    }
    public let network: BitcoinNetwork
    public let isCompressed: Bool

    public init(bytes data: Data, network: BitcoinNetwork = .mainnet) {
        self.data = data
        self.network = network
        let header = data[0]
        self.isCompressed = (header == 0x02 || header == 0x03)
    }
}

extension BitcoinPublicKey {
    public static func verifySigData(for tx: BitcoinTransaction, inputIndex: Int, input: BitcoinInput, sigData: Data, pubKeyData: Data) throws -> Bool {
        // Hash type is one byte tacked on to the end of the signature. So the signature shouldn't be empty.
        guard !sigData.isEmpty else {
            throw ScriptMachineError.error("SigData is empty.")
        }
        // Extract hash type from the last byte of the signature.
        let helper: BitcoinSignatureHashHelper
        if let hashType = BTCSighashType(rawValue: sigData.last!) {
            helper = BitcoinSignatureHashHelper(hashType: hashType)
        } else {
            throw ScriptMachineError.error("Unknown sig hash type")
        }
        // Strip that last byte to have a pure signature.
        let sighash: Data = helper.createSignatureHash(of: tx, for: input, inputIndex: inputIndex)
        let signature: Data = sigData.dropLast()

        return try Crypto.verifySignature(signature, message: sighash, publicKey: pubKeyData)
    }
}

//extension BitcoinPublicKey {
//    public func toAddress() -> Address {
//        return try! Address(data: pubKeyHash, hashType: .pubKeyHash, network: network)
//    }
//}

extension BitcoinPublicKey: Equatable {
    public static func == (lhs: BitcoinPublicKey, rhs: BitcoinPublicKey) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data
    }
}

extension BitcoinPublicKey: CustomStringConvertible {
    public var description: String {
        return data.toHexString()
    }
}

