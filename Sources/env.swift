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
    
    init() {
        self.enclosing = nil
    }
    
    init(env: Env) {
        self.enclosing = env
    }
    
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
        guard values.keys.contains(name.lexeme) else {
            if let enclosing = enclosing { 
                try enclosing.assign(name: name, value: value)
                return
            }
            throw RuntimeError(token: name, message: "Undefined var \(name.lexeme)")
        }
        
        values[name.lexeme] = value
    }
    
    func getAt(distance: Int, name: String) -> Any? {
        return ancestor(distance).values[name] ?? nil
    }
    
    func ancestor(_ distance: Int) -> Env {
        var env = self
        for _ in 0..<distance {
            env = env.enclosing!
        }
        return env
    }
    
    func assignAt(distance: Int, name: Token, value: Any?) {
        let env = ancestor(distance)
        env.values[name.lexeme] = value
    }
}
