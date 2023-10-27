//
//  builtins.swift
//  
//
//  Created by matty on 10/27/23.
//

import Foundation

struct Clock: LoxCallable {
    var arity = 0
    
    func call(interpreter: Interpreter, args: [Any?]) -> Any? {
        Date().timeIntervalSince1970
    }
    
    func toString() -> String {
        "<native fn>"
    }
}
