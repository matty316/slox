//
//  locFunction.swift
//
//
//  Created by matty on 10/27/23.
//

import Foundation

struct LoxFunction: LoxCallable {
    var arity: Int {
        declaration.params.count
    }
    private let declaration: Function
    private var closure: Env
    
    init(declaration: Function, closure: Env) {
        self.declaration = declaration
        self.closure = closure
    }
    
    func call(interpreter: Interpreter, args: [Any?]) throws -> Any? {
        let env = Env(env: closure)
        for (i, p) in declaration.params.enumerated() {
            env.define(name: p.lexeme, value: args[i])
        }
        do {
            try interpreter.executeBlock(stmts: declaration.body, newEnv: env)
        } catch let returnVal as ReturnInterupt {
            return returnVal.value
        }
        
        return nil
    }
    
    func toString() -> String {
        "<fn \(declaration.name.lexeme)>"
    }
}
