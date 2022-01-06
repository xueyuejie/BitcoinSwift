import XCTest
import BIP39swift
import BIP32Swift

@testable import BitcoinSwift

final class BitcoinSwiftTests: XCTestCase {
    let mnemonics = "silver drink visual kid dance solve lock off match plug walnut wool"

    func testBip44KeyExample() throws {
        guard let rootKey = BitcoinKey.fromMnemonics(mnemonics) else {
            return
        }
        let key = try rootKey.derive(path: BitcoinNetwork.mainnet.extendedPath(bip: .bip44))
        
        debugPrint(key.serializePublicKey(version: BitcoinNetwork.mainnet.pubHDNodeVersion(bip: .bip44)) ?? "")

        let childKey = try key.derive(index: 0).derive(index: 0)
        debugPrint(BitcoinPublicKeyAddress(publicKey: childKey.publicKey, network: .mainnet).address ?? "")
    }
    
    func testBip49KeyExample() throws {
        guard let rootKey = BitcoinKey.fromMnemonics(mnemonics) else {
            return
        }
        let key = try rootKey.derive(path: BitcoinNetwork.mainnet.extendedPath(bip: .bip49))
        debugPrint(key.serializePublicKey(version: BitcoinNetwork.mainnet.pubHDNodeVersion(bip: .bip49)) ?? "")
        
        let childKey = try key.derive(index: 0).derive(index: 0)
        debugPrint(childKey.publicKey.toHexString())
        debugPrint(BitcoinScriptHashAddress(publicKey: childKey.publicKey, network: .mainnet).address ?? "")
    }
    
    func testExtendedPubKeyExample() throws {
        guard let rootKey = BitcoinKey.fromMnemonics(mnemonics) else {
            return
        }
        
        let mainnet_bip44Key = try rootKey.derive(path: BitcoinNetwork.mainnet.extendedPath(bip: .bip44))
        let mainnet_bip49Key = try rootKey.derive(path: BitcoinNetwork.mainnet.extendedPath(bip: .bip49))
        
        let testnet_bip44Key = try rootKey.derive(path: BitcoinNetwork.testnet.extendedPath(bip: .bip44))
        let testnet_bip49Key = try rootKey.derive(path: BitcoinNetwork.testnet.extendedPath(bip: .bip49))
        
        debugPrint(mainnet_bip44Key.serializePublicKey(version: BitcoinNetwork.mainnet.pubHDNodeVersion(bip: .bip44)) ?? "")
        debugPrint(mainnet_bip49Key.serializePublicKey(version: BitcoinNetwork.mainnet.pubHDNodeVersion(bip: .bip49)) ?? "")
        
        debugPrint(testnet_bip44Key.serializePublicKey(version: BitcoinNetwork.testnet.pubHDNodeVersion(bip: .bip44)) ?? "")
        debugPrint(testnet_bip49Key.serializePublicKey(version: BitcoinNetwork.testnet.pubHDNodeVersion(bip: .bip49)) ?? "")
    }
    
    func testExtendedPubKey2AccountExample() throws {
        let xpub = "xpub6Bqck4sDNERM8XaP5HEVrZo3kM7GY1hnagdtJKYZQTQwUD8x43MrLND4aDYqPs8AxbD6hWY1rqxbGTPPBDm3BhCohRsYMtEWMNA3RrbxKg2"

        guard let node = HDNode(xpub) else {
            return
        }
        
        guard let hdNode = node.derive(path: "0/2", derivePrivateKey: false) else {
            return
        }
        
        debugPrint(hdNode.publicKey.toHexString())
        debugPrint(BitcoinPublicKeyAddress(publicKey: hdNode.publicKey, network: .mainnet).address ?? "")
    }
    
    func testAddress() {
        debugPrint(BitcoinPublicKeyAddress.isValidAddress("1JNQjrcjU7VzFvebH6krnF9FUioMXMDjsi", network: .mainnet))
        debugPrint(BitcoinScriptHashAddress.isValidAddress("3AseugLkuhKFhVyXTdpbLHiwuzoaxncZAo", network: .mainnet))
    }
}
