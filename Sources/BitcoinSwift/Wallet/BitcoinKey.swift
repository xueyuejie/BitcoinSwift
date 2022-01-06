//
//  BitcoinKey.swift
//  
//
//  Created by math on 2021/12/9.
//

import Foundation
import BIP39swift
import BIP32Swift

public struct BitcoinKey {
    private var node: HDNode
    
    public var publicKey: Data {
        return node.publicKey
    }
    
    public var pubKeyHash: Data {
        return publicKey.hash160()!
    }
    
    public var privateKey: Data? {
        return node.privateKey
    }

    public var witnessRedeemScript:Data {
        var data = Data()
        data.appendUInt8(OpCode.OP_0.value)
        data.appendVarInt(UInt64(pubKeyHash.count))
        data.append(pubKeyHash)
        return data
    }
    
    public static func fromMnemonics(_ mnemonics: String) -> Self? {
        guard let seed = BIP39.seedFromMmemonics(mnemonics) else {
            return nil
        }
        guard let rootNode = HDNode(seed: seed) else {
            return nil
        }
        
       return BitcoinKey(node: rootNode)
    }
    
    public func serializePublicKey(version: HDNode.HDversion) -> String? {
        return node.serializeToString(serializePublic: true, version: version)
    }
    
    public func serializePrivateKey(version: HDNode.HDversion) -> String? {
        return node.serializeToString(serializePublic: false, version: version)
    }
    
    public func derive(path: String) throws -> BitcoinKey {
        guard let childNode = node.derive(path: path) else {
            throw Error.invalidDerivePath
        }
        return BitcoinKey(node: childNode)
    }
    
    public func derive(index: UInt32, hardened: Bool = false) throws -> BitcoinKey {
        guard let childNode = node.derive(index: index, derivePrivateKey: true, hardened: hardened) else {
            throw Error.invalidDerivePath
        }
        return BitcoinKey(node: childNode)
    }
    
}

public extension BitcoinKey {
    enum Error: String, LocalizedError {
        case invalidDerivePath
    }
}
