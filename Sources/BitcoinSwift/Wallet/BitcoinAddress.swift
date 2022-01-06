//
//  BitcoinAddress.swift
//  
//
//  Created by math on 2021/12/9.
//

import Foundation
import CryptoSwift

public protocol BitcoinAddress {
    var network: BitcoinNetwork { get }
    var publicKey: Data {set get}
    var addressData: Data? { get }
    var address: String? { get }
    
    init(publicKey: Data, network: BitcoinNetwork)
    
    static func decodeAddress(_ address: String) -> Data?
    static func encodeAddress(_ addressData: Data) -> String?
    static func isValidAddress(_ address: String, network: BitcoinNetwork) -> Bool
}

public struct BitcoinPublicKeyAddress: BitcoinAddress {
    public var publicKey: Data
    public var network: BitcoinNetwork
    public var addressData: Data? {
        guard let hash = publicKey.hash160() else {
            return nil
        }
        
        var data = Data()
        data.append(network.pubKeyHashPrefix)
        data.append(hash)
        return data
    }
    
    public var address: String? {
        return self.addressData?.bytes.base58CheckEncodedString
    }
    
    public init(publicKey: Data, network: BitcoinNetwork) {
        self.publicKey = publicKey
        self.network = network
    }
    
    public static func decodeAddress(_ address: String) -> Data? {
        return address.base58CheckDecodedData
    }
    
    public static func encodeAddress(_ addressData: Data) -> String? {
        return addressData.bytes.base58CheckEncodedString
    }
    
    public static func isValidAddress(_ address: String, network: BitcoinNetwork = .mainnet) -> Bool {
        guard let data = BitcoinPublicKeyAddress.decodeAddress(address) else { return false }
        guard data.count == 1 + 20, data.prefix(1) == network.pubKeyHashPrefix else { return false }
        return true
    }
}

public struct BitcoinScriptHashAddress: BitcoinAddress {
    public var publicKey: Data
    public var network: BitcoinNetwork
    public var addressData: Data? {
        guard let hash = publicKey.hash160() else {
            return nil
        }
        
        var redeem = Data()
        redeem.append(Data(hex: "0014"))
        redeem.append(hash)
        
        guard let payload = redeem.hash160() else {
            return nil
        }
        
        var checksumScript = Data()
        checksumScript.append(network.scriptHashPrefix)
        checksumScript.append(payload)
        
        let checksum = checksumScript.hash256().subdata(in: 0..<4)
    
        var data = Data()
        data.append(network.scriptHashPrefix)
        data.append(payload)
        data.append(checksum)
        
        return data
    }
    
    public var address: String? {
        return self.addressData?.bytes.base58EncodedString
    }
    
    public init(publicKey: Data, network: BitcoinNetwork) {
        self.publicKey = publicKey
        self.network = network
    }
    
    public static func decodeAddress(_ address: String) -> Data? {
        return address.base58DecodedData
    }
    
    public static func encodeAddress(_ addressData: Data) -> String? {
        return addressData.bytes.base58EncodedString
    }
    
    public static func isValidAddress(_ address: String, network: BitcoinNetwork = .mainnet) -> Bool {
        guard let data = BitcoinScriptHashAddress.decodeAddress(address) else { return false }
        guard data.count == 1 + 20 + 4, data.prefix(1) == network.scriptHashPrefix else { return false }
        
        let checksumScript = data.subdata(in: 0..<21)
        let checksum = checksumScript.hash256().subdata(in: 0..<4)
        
        guard checksum == data.suffix(4) else { return false }
        
        return true
    }
}
