//
//  interpreter.swift
//
//
//  Created by matty on 10/23/23.
//

import Foundation

class Interpreter {
    struct BreakInterupt: Error {}
    
    typealias R = Any
    
    var globals = Env()
    private var env: Env
    private var locals = [Expr: Int]()
    
    init() {
        self.env = globals
        globals.define(name: "clock", value: Clock())
    }
    
    func interpret(statements: [Stmt]) {
        do {
            for stmt in statements {
                try execute(stmt: stmt)
            }
        } catch let error as RuntimeError {
            slox.runtimeError(error)
        } catch is BreakInterupt {
            //no-op
        } catch {
            
        }
    }
    
    func interpretStmt(statement: Stmt) {
        do {
            if let statement = statement as? Expression {
                let val = try evaluate(statement.expression)
                print(stringify(val))
            } else {
                try execute(stmt: statement)
            }
        } catch let error as RuntimeError {
            slox.runtimeError(error)
        } catch is BreakInterupt {
            //no-op
        } catch {
            
        }
    }
    
    //MARK: Helpers
    @discardableResult
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
        } else if let expr = expr as? Bool {
            return expr ? "true" : "false"
        }
        
        return expr as? String ?? ""
    }
    
    @discardableResult
    private func execute(stmt: Stmt) throws -> R? {
        try stmt.accept(visitor: self)
    }
    
    func executeBlock(stmts: [Stmt], newEnv: Env) throws {
        let previous = env
        defer {
            env = previous
        }
        do {
            self.env = newEnv
            
            for stmt in stmts {
                try execute(stmt: stmt)
            }
        } catch let error as RuntimeError {
            slox.runtimeError(error)
        } catch let error as BreakInterupt {
            throw error
        }
    }
    
    func resolve(expr: Expr, _ depth: Int) {
        locals[expr] = depth
    }
    
    private func lookUpVar(name: Token, expr: Expr) throws -> R? {
        let distance = locals[expr]
        if let distance = distance {
            return env.getAt(distance: distance, name: name.lexeme)
        } else {
            return try globals.get(name: name)
        }
    }
}

//MARK: StmtVisitor
extension Interpreter: StmtVisitor {
    func visitFunExpr(expr: Fun) throws -> R? {
        return LoxFunction(declaration: expr, closure: env)
    }
    
    func visitFunctionStmt(stmt: Function) throws -> R? {
        let function = LoxFunction(name: stmt.name.lexeme, declaration: stmt.function, closure: env)
        env.define(name: stmt.name.lexeme, value: function)
        return nil
    }
    
    func visitWhileStmt(stmt: While) throws -> R? {
        while isTruthy(try evaluate(stmt.condition)) {
            do {
                try execute(stmt: stmt.body)
            } catch is BreakInterupt {
                break
            } catch {
                throw error
            }
        }
        return nil
    }
    
    func visitBreakStmt(stmt: Break) throws -> R? {
        throw BreakInterupt()
    }
    
    func visitReturnStmt(stmt: Return) throws -> R? {
        var value: Any? = nil
        if let stmtVal = stmt.value { value = try evaluate(stmtVal) }
        
        throw ReturnInterupt(value: value)
    }
    
    @discardableResult
    func visitExpressionStmt(stmt: Expression) throws -> R? {
        try evaluate(stmt.expression)
        return nil
    }
    
    @discardableResult
    func visitPrintStmt(stmt: Print) throws -> R? {
        let val = try evaluate(stmt.expression)
        print(stringify(val))
        return nil
    }
    
    func visitIfStmt(stmt: If) throws -> R? {
        if isTruthy(try evaluate(stmt.condition)) {
            try execute(stmt: stmt.thenBranch)
        } else if (stmt.elseBranch != nil) {
            try execute(stmt: stmt.elseBranch!)
        }
        return nil
    }
    
    func visitBlockStmt(stmt: Block) throws -> R? {
        try executeBlock(stmts: stmt.statements, newEnv: Env(env: env))
    }
    
    @discardableResult
    func visitVarStmt(stmt: Var) throws -> R? {
        var value: R? = nil
        if let initializer = stmt.initializer {
            value = try evaluate(initializer)
        }
        
        env.define(name: stmt.name.lexeme, value: value)
        return nil
    }
}

//MARK: Expr: Visitor
extension Interpreter: ExprVisitor {
    func visitVariableExpr(expr: Variable) throws -> R? {
        return try lookUpVar(name: expr.name, expr: expr)
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
            
            if left is String || right is String {
                return stringify(left) + stringify(right)
            }
            
            throw RuntimeError(token: expr.op, message: "Operands must be two numbers or at least one string")
        case .SLASH:
            try checkNumberOps(expr.op, left, right)
            if (right as! Double) != 0 {
                return (left as! Double) / (right as! Double)
            }
            throw RuntimeError(token: expr.op, message: "Cannot divide by zero")
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
    
    func visitAssignExpr(expr: Assign) throws -> R? {
        let value = try evaluate(expr.value)
        
        let distance = locals[expr]
        if let distance = distance {
            try env.assignAt(distance: distance, name: expr.name, value: value)
        } else {
            try globals.assign(name: expr.name, value: value)
        }
        
        return value
    }
    
    func visitLogicalExpr(expr: Logical) throws -> R? {
        let left = try evaluate(expr.left)
        
        if expr.op.tokenType == .OR {
            if isTruthy(left) { return left }
        } else {
            if !isTruthy(left) { return left }
        }
        
        return try evaluate(expr.right)
    }
    
    func visitCallExpr(expr: Call) throws -> R? {
        let callee = try evaluate(expr.callee)
        
        var args = [Any?]()
        for arg in expr.args {
            args.append(try evaluate(arg))
        }
        
        guard let callee = callee as? LoxCallable else {
            throw RuntimeError(token: expr.paren, message: "can only call functions and classes")
        }
        
        let function = callee
        
        guard args.count == function.arity else {
            throw RuntimeError(token: expr.paren, message: "expect \(function.arity) args but got \(args.count)")
        }
        
        return try function.call(interpreter: self, args: args)
    }
}

extension Expr: Hashable {
    static func == (lhs: Expr, rhs: Expr) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {}
}
