//
//  loxCallable.swift
//
//
//  Created by matty on 10/26/23.
//

import Foundation

protocol LoxCallable {
    var arity: Int { get }
    func call(interpreter: Interpreter, args: [Any?]) -> Any?
}
