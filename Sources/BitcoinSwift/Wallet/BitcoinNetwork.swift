//
//  File.swift
//  
//
//  Created by math on 2021/12/9.
//

import Foundation
import CryptoSwift
import BIP32Swift

public enum BitcoinBIP: String {
    case bip44
    case bip49
}
public enum BitcoinNetwork: String {
    case mainnet
    case testnet
    case regtest

    public var pubKeyHashPrefix: Data {
        switch self {
        case .mainnet:
            return Data(hex: "00")
        case .testnet:
            return Data(hex: "6f")
        case .regtest:
            return Data(hex: "6f")
        }
    }
    
    public var scriptHashPrefix: Data {
        switch self {
        case .mainnet:
            return Data(hex: "05")
        case .testnet:
            return Data(hex: "c4")
        case .regtest:
            return Data(hex: "c4")
        }
    }
    
    public func extendedPath(bip: BitcoinBIP) -> String {
        switch bip {
        case .bip44:
            switch self {
            case .mainnet:
                return "m/44'/0'/0'"
            case .testnet:
                return "m/44'/1'/0'"
            case .regtest:
                return "m/44'/1'/0'"
            }
        case .bip49:
            switch self {
            case .mainnet:
                return "m/49'/0'/0'"
            case .testnet:
                return "m/49'/1'/0'"
            case .regtest:
                return "m/49'/1'/0'"
            }
        }
    }
    
    public func pubKeyPrefix(bip: BitcoinBIP) -> Data {
        switch bip {
        case .bip44:
            switch self {
            case .mainnet:
                return Data(hex: "0488b21e")
            case .testnet:
                return Data(hex: "043587cf")
            case .regtest:
                return Data(hex: "043587cf")
            }
        case .bip49:
            switch self {
            case .mainnet:
                return Data(hex: "049d7cb2")
            case .testnet:
                return Data(hex: "044a5262")
            case .regtest:
                return Data(hex: "044a5262")
            }
        }
    }
    
    public func privKeyPrefix(bip: BitcoinBIP) -> Data {
        switch bip {
        case .bip44:
            switch self {
            case .mainnet:
                return Data(hex: "0488ade4")
            case .testnet:
                return Data(hex: "04358394")
            case .regtest:
                return Data(hex: "04358394")
            }
        case .bip49:
            switch self {
            case .mainnet:
                return Data(hex: "049d7878")
            case .testnet:
                return Data(hex: "044a4e28")
            case .regtest:
                return Data(hex: "044a4e28")
            }
        }
    }
    
    public func pubHDNodeVersion(bip: BitcoinBIP) -> HDNode.HDversion {
        var hdVer = HDNode.HDversion()
        hdVer.publicPrefix = self.pubKeyPrefix(bip: bip)
        hdVer.privatePrefix = self.privKeyPrefix(bip: bip)
        return hdVer
    }
    
}
