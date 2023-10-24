//
//  astPrinter.swift
//
//
//  Created by matty on 10/23/23.
//

import Foundation

class AstPrinter: Visitor {
    func print(expr: Expr) -> String? {
        let text: String? = try? expr.accept(visitor: self)
        return text
    }
    
    func visitBinaryExpr(expr: Binary) -> String? {
        return parenthesize(name: expr.op.lexeme, exprs: [expr.left, expr.right])
    }
    
    func visitGroupingExpr(expr: Grouping) -> String? {
        return parenthesize(name: "group", exprs: [expr.expression])
    }
    
    func visitLiteralExpr(expr: Literal) -> String? {
        guard let val = expr.value else { return nil }
        return "\(val)"
    }
    
    func visitUnaryExpr(expr: Unary) -> String? {
        return parenthesize(name: expr.op.lexeme, exprs: [expr.right])
    }
    
    typealias R = String
    
    func parenthesize(name: String, exprs: [Expr]) -> String {
        var str = ""
        
        str.append("(")
        str.append(name)
        for e in exprs {
            str.append(" ")
            let text: String! = try? e.accept(visitor: self)
            str.append(text)
        }
        str.append(")")
        
        return str
    }
    
}
