//
//  resolver.swift
//
//
//  Created by matty on 10/28/23.
//

import Foundation

class Resolver {
    class Scopes {
        var isEmpty: Bool { scopes.isEmpty }
        var count: Int { scopes.count }
        private var scopes: [[String: Bool]] = [[String: Bool]]()
        
        func push(scope: [String: Bool]) {
            scopes.append(scope)
        }
        
        func pop() -> [String: Bool]? {
            scopes.popLast()
        }
        
        func peek() -> [String: Bool]? {
            return scopes.last
        }
        
        func peekAndUpdate(name: String, ready: Bool) {
            guard !scopes.isEmpty else { return }
            scopes[scopes.count-1][name] = ready
        }
        
        subscript(i: Int) -> [String: Bool] {
            get {
                scopes[i]
            }
            set(newValue) {
                scopes[i] = newValue
            }
        }
    }
    
    enum FunctionType {
        case None
        case Function
    }
    
    typealias R = Void
    
    private var interpreter: Interpreter = Interpreter()
    
    private var scopes = Scopes()
    private var currentFunction: FunctionType = .None
    
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
    
    //MARK: Helpers
    func resolve(stmts: [Stmt]) throws {
        for stmt in stmts {
            try resolve(stmt: stmt)
        }
    }
    
    private func resolve(stmt: Stmt) throws -> Void? {
        try stmt.accept(visitor: self)
    }
    
    private func resolve(expr: Expr) throws -> Void? {
        try expr.accept(visitor: self)
    }
    
    private func beginScope() {
        scopes.push(scope: [String: Bool]())
    }
    
    private func endScope() {
        _ = scopes.pop()
    }
    
    private func declare(name: Token) {
        let scope = scopes.peek()
        if scope?.keys.contains(name.lexeme) == true {
            slox.error(token: name, message: "Already have a var with this name in scope")
        }
        scopes.peekAndUpdate(name: name.lexeme, ready: false)
    }
    
    private func define(name: Token) {
        scopes.peekAndUpdate(name: name.lexeme, ready: true)
    }
    
    private func resolveLocal(expr: Expr, name: Token) {
        var i = scopes.count - 1
        while i >= 0 {
            if scopes[i].keys.contains(name.lexeme) {
                interpreter.resolve(expr: expr, scopes.count - 1 - i)
                return
            }
            i -= 1
        }
    }
    
    private func resolveFunction(function: Fun, functionType: FunctionType) throws {
        let enclosingFunction = currentFunction
        currentFunction = functionType
        beginScope()
        for param in function.params {
            declare(name: param)
            define(name: param)
        }
        try resolve(stmts: function.body)
        endScope()
        currentFunction = enclosingFunction
    }
}

//MARK: StmtVisitor
extension Resolver: StmtVisitor {
    func visitBlockStmt(stmt: Block) throws -> Void? {
        beginScope()
        try resolve(stmts: stmt.statements)
        endScope()
        return nil
    }
    
    func visitExpressionStmt(stmt: Expression) throws -> Void? {
        try resolve(expr: stmt.expression)
        return nil
    }
    
    func visitIfStmt(stmt: If) throws -> Void? {
        try resolve(expr: stmt.condition)
        try resolve(stmt: stmt.thenBranch)
        if let elseBranch = stmt.elseBranch { try resolve(stmt: elseBranch) }
        return nil
    }
    
    func visitPrintStmt(stmt: Print) throws -> Void? {
        try resolve(expr: stmt.expression)
        return nil
    }
    
    func visitVarStmt(stmt: Var) throws -> Void? {
        declare(name: stmt.name)
        if let initializer = stmt.initializer {
            try resolve(expr: initializer)
        }
        define(name: stmt.name)
        return nil
    }
    
    func visitWhileStmt(stmt: While) throws -> Void? {
        try resolve(expr: stmt.condition)
        try resolve(stmt: stmt.body)
        return nil
    }
    
    func visitBreakStmt(stmt: Break) throws -> Void? {
        return nil
    }
    
    func visitFunctionStmt(stmt: Function) throws -> Void? {
        declare(name: stmt.name)
        define(name: stmt.name)
        try resolveFunction(function: stmt.function, functionType: .Function)
        return nil
    }
    
    func visitReturnStmt(stmt: Return) throws -> Void? {
        if (currentFunction == .None) { slox.error(token: stmt.keyword, message: "Cant have return at top level")}
        if let value = stmt.value { try resolve(expr: value) }
        return nil
    }
}

//MARK: ExprVisitor
extension Resolver: ExprVisitor {
    func visitAssignExpr(expr: Assign) throws -> Void? {
        try resolve(expr: expr.value)
        resolveLocal(expr: expr, name: expr.name)
        return nil
    }
    
    func visitBinaryExpr(expr: Binary) throws -> Void? {
        try resolve(expr: expr.left)
        try resolve(expr: expr.right)
        return nil
    }
    
    func visitCallExpr(expr: Call) throws -> Void? {
        try resolve(expr: expr.callee)
        
        for arg in expr.args {
            try resolve(expr: arg)
        }
        return nil
    }
    
    func visitGroupingExpr(expr: Grouping) throws -> Void? {
        try resolve(expr: expr.expression)
        return nil
    }
    
    func visitLiteralExpr(expr: Literal) throws -> Void? {
        return nil
    }
    
    func visitLogicalExpr(expr: Logical) throws -> Void? {
        try resolve(expr: expr.left)
        try resolve(expr: expr.right)
        return nil
    }
    
    func visitUnaryExpr(expr: Unary) throws -> Void? {
        try resolve(expr: expr.right)
        return nil
    }
    
    func visitVariableExpr(expr: Variable) throws -> Void? {
        if !scopes.isEmpty && scopes.peek()?[expr.name.lexeme] == false {
            slox.error(token: expr.name, message: "Can't read local var in its own init")
        }
        
        resolveLocal(expr: expr, name: expr.name)
        return nil
    }
    
    func visitFunExpr(expr: Fun) throws -> Void? {
        try resolveFunction(function: expr, functionType: .Function)
        return nil
    }
}
