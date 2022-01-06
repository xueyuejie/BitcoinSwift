//
//  BitcoinOutput.swift
//  
//
//  Created by xgblin on 2021/12/27.
//

import Foundation

public struct BitcoinOutput {
    let value:UInt64
    var scriptLenth:UInt64
    var script:Data
    
    public init(value:UInt64,address:String = "",dataHex:String = "",script:Data = Data()) {
        var scriptData:Data
        if !address.isEmpty {
            scriptData = Script(address: address)!.data
        } else if !dataHex.isEmpty {
            let hexData = Data(hex: dataHex)!
            scriptData = Data(hex: "6a")!
            scriptData.appendVarInt(UInt64(hexData.count))
            scriptData.appendData(hexData)
        } else {
            scriptData = script
        }
        self.value = value
        self.scriptLenth = UInt64(scriptData.count)
        self.script = scriptData
    }
    
    public func serialized() -> Data {
        var data = Data()
        data.appendUInt64(value)
        data.appendVarInt(scriptLenth)
        data.append(script)
        return data
    }
}
