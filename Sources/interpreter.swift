//
//  interpreter.swift
//
//
//  Created by matty on 10/23/23.
//

import Foundation

class Interpreter: Visitor {
    typealias R = Any
    
    func interpret(expr: Expr) {
        do {
            let val = try evaluate(expr)
            print(stringify(val))
        } catch let error as RuntimeError {
            slox.runtimeError(error)
        } catch {
            print(error)
        }
    }

    func visitBinaryExpr(expr: Binary) throws -> R? {
        let left = try evaluate(expr.left)
        let right = try evaluate(expr.right)
        
        switch expr.op.tokenType {
        case .GT:
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) > (right as! Double)
        case .GTEQ: 
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) >= (right as! Double)
        case .LT: 
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) < (right as! Double)
        case .LTEQ:
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) <= (right as! Double)
        case .MINUS:
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) - (right as! Double)
        case .BANGEQ: 
            return !isEqual(left, right)
        case .EQEQ: 
            return isEqual(left, right)
        case .PLUS:
            if left is Double && right is Double {
                return (left as! Double) + (right as! Double)
            }
            if left is String && right is String {
                return (left as! String) + (right as! String)
            }
            
            throw RuntimeError(token: expr.op, message: "Operands must be two numbers or two strings")
        case .SLASH:
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) / (right as! Double)
        case .STAR:
            try checkNumberOps(expr.op, left, right)
            return (left as! Double) * (right as! Double)
        default: return nil
        }
    }
    
    func visitGroupingExpr(expr: Grouping) throws -> R? {
        return try evaluate(expr.expression)
    }
    
    func visitLiteralExpr(expr: Literal) -> R? {
        return expr.value
    }
    
    func visitUnaryExpr(expr: Unary) throws -> R? {
        let right = try evaluate(expr.right)
        switch expr.op.tokenType {
        case .MINUS:
            try checkNumberOp(expr.op, right)
            return -(right as! Double)
        case .BANG:
            return !isTruthy(right)
        default:
            return nil
        }
    }
    
    //MARK: Helpers
    func evaluate(_ expr: Expr) throws -> R? {
        return try expr.accept(visitor: self)
    }
    
    func isTruthy(_ expr: Any?) -> Bool {
        if expr == nil { return false }
        if let expr = expr as? Bool { return expr }
        return true
    }
    
    func isEqual(_ a: Any?, _ b: Any?) -> Bool {
        if a == nil && b == nil { return true }
        if (a == nil) { return false }
        
        guard let a = a as? AnyHashable, let b = b as? AnyHashable else { return false }
        
        return a == b
    }
    
    func checkNumberOp(_ op: Token, _ operand: Any?) throws {
        if operand is Double { return }
        throw RuntimeError(token: op, message: "Operand must be a number")
    }
    
    func checkNumberOps(_ op: Token, _ left: Any?, _ right: Any?) throws {
        if left is Double && right is Double { return }
        throw RuntimeError(token: op, message: "Operands must be numbers")
    }
    
    private func stringify(_ expr: Any?) -> String {
        if expr == nil { return "nil" }
        
        if let expr = expr as? Double {
            var text = String(expr)
            if text.suffix(2) == ".0" {
                let start = text.startIndex
                let beforeEnd = text.index(text.endIndex, offsetBy: -2)
                text = String(text[start..<beforeEnd])
            }
            return text
        }
        
        return expr as? String ?? ""
    }
}
