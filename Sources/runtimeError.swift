//
//  runtimeError.swift
//
//
//  Created by matty on 10/24/23.
//

import Foundation

class RuntimeError: Error {
    let token: Token
    let message: String
    
    init(token: Token, message: String) {
        self.message = message
        self.token = token
    }
}
