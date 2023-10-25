//
//  env.swift
//
//
//  Created by matty on 10/24/23.
//

import Foundation

class Env {
    private var values = [String: Any?]()
    var enclosing: Env?
    
    func define(name: String, value: Any?) {
        values[name] = value
    }
    
    func get(name: Token) throws -> Any? {
        guard let val = values[name.lexeme] else {
            if let enclosing = enclosing { return try enclosing.get(name: name) }
            throw RuntimeError(token: name, message: "Undefined var \(name.lexeme)")
        }
        return val
    }
    
    func assign(name: Token, value: Any?) throws {
        guard values[name.lexeme] != nil else {
            if let enclosing = enclosing { try enclosing.assign(name: name, value: value) }
            throw RuntimeError(token: name, message: "Undefined var \(name.lexeme)")
        }
        
        values[name.lexeme] = value
    }
}
