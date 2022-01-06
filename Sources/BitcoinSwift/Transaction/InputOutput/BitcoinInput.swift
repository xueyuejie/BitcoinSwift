//
//  BitcoinInput.swift
//  
//
//  Created by xgblin on 2021/12/27.
//

import Foundation

public class BitcoinInput {
    public var pub:String
    public var path:String
    
    public let address:String
    public let prev_hash:Data
    public let index:UInt32
    public let value:UInt64
    public let sequence:UInt32
    public var signatureScript:Data
    
    var witnessData = Script()
    
    var isSegwit:Bool = false
    
    var isCoinbase:Bool {
        let prev32 = prev_hash.subdata(in: 0 ..< 32)
        return index == 4294967295 && prev_hash.count == 32 && prev32 != ZeroData256
    }
    
    public init(address:String,
         prev_hash:Data,
         index:UInt32,
         value:UInt64,
         signatureScript:Data,
         sequence:UInt32 = 4294967295,
         pub:String = "",
         path:String = "") {
        self.address = address
        self.prev_hash = Data(prev_hash.reversed())
        self.index = index
        self.value = value
        self.signatureScript = signatureScript
        self.sequence = sequence
        self.pub = pub
        self.path = path
    }
    
    func getInput() -> BitcoinInput? {
        if BitcoinPublicKeyAddress.isValidAddress(self.address) {
            return BitcoinInput(
                address:self.address,
                prev_hash:Data(self.prev_hash.reversed()),
                index:self.index,
                value:self.value,
                signatureScript:self.signatureScript
            )
        } else if BitcoinScriptHashAddress.isValidAddress(self.address) {
            return BitcoinSegwitInput(
                address:self.address,
                prev_hash:Data(self.prev_hash.reversed()),
                index:self.index,
                value:self.value,
                signatureScript:self.signatureScript
            )
        } else {
            return nil
        }
    }
    
    func signedInput(transaction:BitcoinTransaction,inputIndex: Int,key:BitcoinKey) -> BitcoinInput?{
        let sighash: Data = transaction.sighashHelper.createSignatureHash(of: transaction, for: self, inputIndex: inputIndex)
        var signature: Data
        do {
            signature = try Crypto.sign(sighash, privateKey: key.privateKey!)
        } catch {
            return nil
        }
        let pubkey = key.publicKey

        // Create Signature Script
        let sigWithHashType: Data = signature + [transaction.sighashHelper.hashType.uint8]
        var unlockingScript: Script
        do {
            unlockingScript = try Script()
                .appendData(sigWithHashType)
                .appendData(pubkey)
        } catch {
            return nil
        }
        self.signatureScript = unlockingScript.data
        return self
    }
    
    func serialized() -> Data {
        var data = Data()
        data.append(prev_hash)
        data.appendUInt32(index)
        if isCoinbase {
//            data.ap
        } else {
            data.appendVarInt(UInt64(signatureScript.count))
            data.append(signatureScript)
        }
        data.appendUInt32(sequence)
        return data
    }
}

public class BitcoinSegwitInput:BitcoinInput {
    override var isSegwit: Bool{
        get{return true}
        set{}
    }
    
    override func signedInput(transaction: BitcoinTransaction, inputIndex: Int, key: BitcoinKey) -> BitcoinInput? {
        let hex = key.pubKeyHash.toHexString()
        let scriptCode:Data = Data(hex: "1976a914\(hex)88ac")
        self.signatureScript = scriptCode
        let sighash: Data = transaction.sighashHelper.createSignatureHash(of: transaction, for: self, inputIndex: inputIndex)
        var signature: Data
        var witnessscript:Script
        do {
            signature = try Crypto.sign(sighash, privateKey: key.privateKey!)
            signature.appendUInt8(SIGHASH_ALL)
            witnessscript = try Script().appendData(signature).appendData(key.publicKey)
        } catch {
            return nil
        }
        self.witnessData = witnessscript
        self.signatureScript = key.witnessRedeemScript
        return self
    }
    
    override func serialized() -> Data {
        var data = Data()
        data.append(prev_hash)
        data.appendUInt32(index)
        data.appendVarInt(23)
        data.append(22)
        data.append(signatureScript)
        data.appendUInt32(sequence)
        return data
    }
}
