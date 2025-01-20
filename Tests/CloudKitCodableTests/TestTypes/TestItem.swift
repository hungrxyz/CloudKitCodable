//
//  TestItem.swift
//  CloudKitCodable
//
//  Created by marko on 25/12/2024.
//

import Foundation

struct TestItem: Hashable, Codable {
    
    let field: String
    let reference: String
    let references: [String]
    
}
