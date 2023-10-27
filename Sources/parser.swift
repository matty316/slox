//
//  parser.swift
//
//
//  Created by matty on 10/23/23.
//

import Foundation

class Parser {
    struct ParserError: Error {}
    private let tokens: [Token]
    private var current = 0
    private var isAtEnd: Bool {
        peek.tokenType == .EOF
    }
    private var peek: Token {
        tokens[current]
    }
    private var previous: Token {
        tokens[current - 1]
    }
    
    var loopDepth = 0
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func parse() -> [Stmt] {
        var statements = [Stmt]()
        
        while !isAtEnd {
            guard let declaration = declaration() else { return statements }
            statements.append(declaration)
        }
        
        return statements
    }
    
    private func declaration() -> Stmt? {
        do {
            if match([.FUN]) { return try function(kind: "function") }
            if match([.VAR]) { return try varDeclaration() }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }
    
    private func function(kind: String) throws -> Stmt {
        let name = try consume(.IDENT, "Expect \(kind) name.")
        try consume(.LPAREN, "Expected left paren")
        var params = [Token]()
        if !check(.RPAREN) {
            repeat {
                if params.count >= 255 {
                    error(peek, "cannot have more that 255 params")
                }
                
                params.append(try consume(.IDENT, "expect param name"))
            } while match([.COMMA])
        }
        try consume(.RPAREN, "expected right paren after params")
        try consume(.LBRACE, "Expect right brace before \(kind) body")
        let body = try block()
        return Function(name: name, params: params, body: body)
    }
    
    private func varDeclaration() throws -> Var {
        let name = try consume(.IDENT, "expected var name")
        
        var initializer: Expr? = nil
        if match([.EQ]) {
            initializer = try expression()
        }
        
        try consume(.SEMICOLON, "Expected a semicolon")
        return Var(name: name, initializer: initializer)
    }
    
    private func statement() throws -> Stmt {
        if match([.FOR]) { return try forStatement() }
        if match([.IF]) { return try ifStatement() }
        if match([.PRINT]) { return try printStatement() }
        if match([.RETURN]) { return try returnStatement() }
        if match([.BREAK]) {
            if loopDepth > 0 {
                return try breakStatement()
            } else {
                throw self.error(previous, "cannot have break outside loop")
            }
        }
        if match([.WHILE]) { return try whileStatement() }
        if match([.LBRACE]) { return Block(statements: try block() )}
        return try expressionStatement()
    }
    
    private func returnStatement() throws -> Return {
        let keyword = previous
        var value: Expr? = nil
        if !check(.SEMICOLON) {
            value = try expression()
        }
        
        try consume(.SEMICOLON, "expect semicolon after return")
        return Return(keyword: keyword, value: value)
    }
    
    private func forStatement() throws -> Stmt {
        try consume(.LPAREN, "expected left paren")
        
        var initializer: Stmt?
        if match([.SEMICOLON]) {
            initializer = nil
        } else if match([.VAR]) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }
        
        var condition: Expr? = nil
        if !check(.SEMICOLON) {
            condition = try expression()
        }
        try consume(.SEMICOLON, "expected a semicolon after condition")
        
        var increment: Expr? = nil
        if !check(.RPAREN) {
            increment = try expression()
        }
        try consume(.RPAREN, "expected a right paren")
        loopDepth += 1
        var body = try statement()
        
        if let increment = increment {
            body = Block(statements: [body, Expression(expression: increment)])
        }
        
        if let condition = condition {
            body = While(condition: condition, body: body)
        } else {
            body = While(condition: Literal(value: true), body: body)
        }
        
        if let initializer = initializer {
            body = Block(statements: [initializer, body])
        }
        loopDepth -= 1
        return body
    }
    
    private func ifStatement() throws -> If {
        try consume(.LPAREN, "Expect '(' after 'if'")
        let condition = try expression()
        try consume(.RPAREN, "Expect ')' after 'if' condition")
        
        let thenBranch = try statement()
        var elseBranch: Stmt?
        if match([.ELSE]) {
            elseBranch = try statement()
        }
        
        return If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    private func printStatement() throws -> Print {
        let val = try expression()
        try consume(.SEMICOLON, "Expected a Semicolon")
        return Print(expression: val)
    }
    
    private func whileStatement() throws -> While {
        loopDepth += 1
        try consume(.LPAREN, "expected left paren")
        let condition = try expression()
        try consume(.RPAREN, "expected right paren")
        let stmt = try statement()
        loopDepth -= 1
        return While(condition: condition, body: stmt)
    }
    
    private func block() throws -> [Stmt] {
        var stmts = [Stmt]()
        
        while !check(.RBRACE) && !isAtEnd {
            if let declaration = declaration() {
                stmts.append(declaration)
            }
        }
        
        try consume(.RBRACE, "Expected } after block")
        return stmts
    }
    
    private func breakStatement() throws -> Stmt {
        let stmt = Break()
        try consume(.SEMICOLON, "expected a semicolon after break")
        return stmt
    }
    
    private func expressionStatement() throws -> Expression {
        let expr = try expression()
        try consume(.SEMICOLON, "Expected a Semicolon")
        return Expression(expression: expr)
    }
    
    private func expression() throws -> Expr {
        return try assignment()
    }
    
    private func assignment() throws -> Expr {
        let expr = try or()
        
        if match([.EQ]) {
            let equals = previous
            let value = try assignment()
            
            if let expr = expr as? Variable {
                let name = expr.name
                return Assign(name: name, value: value)
            }
            
            error(equals, "invalid assignment target")
        }
        
        return expr
    }
    
    private func or() throws -> Expr {
        var expr = try and()
        
        while match([.OR]) {
            let op = previous
            let right = try and()
            expr = Logical(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func and() throws -> Expr {
        var expr = try equality()
        
        while match([.AND]) {
            let op = previous
            let right = try equality()
            expr = Logical(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func equality() throws -> Expr {
        var expr = try comparison()
        while match([.BANGEQ, .EQEQ]) {
            let op = previous
            let right = try comparison()
            expr = Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func comparison() throws -> Expr {
        var expr = try term()
        while match([.GT, .GTEQ, .LT, .LTEQ]) {
            let op = previous
            let right = try term()
            expr = Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func term() throws -> Expr {
        var expr = try factor()
        
        while match([.MINUS, .PLUS]) {
            let op = previous
            let right = try factor()
            expr = Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func factor() throws -> Expr {
        var expr = try unary()
        
        while match([.SLASH, .STAR]) {
            let op = previous
            let right = try unary()
            expr = Binary(left: expr, op: op, right: right)
        }
        
        return expr
    }
    
    private func unary() throws -> Expr {
        if match([.BANG, .MINUS]){
            let op = previous
            let right = try unary()
            return Unary(op: op, right: right)
        }
        
        return try call()
    }
    
    private func call() throws -> Expr {
        var expr = try primary()
        
        while true {
            if match([.LPAREN]) {
                expr = try finishCall(callee: expr)
            } else {
                break
            }
        }
        
        return expr
    }
    
    private func finishCall(callee: Expr) throws -> Expr {
        var args = [Expr]()
        if !check(.RPAREN) {
            repeat {
                if args.count >= 255 {
                    error(peek, "cant have more that 255 args")
                }
                args.append(try expression())
            } while match([.COMMA])
        }
        
        let paren = try consume(.RPAREN, "expected right paren")
        
        return Call(callee: callee, paren: paren, args: args)
    }
    
    private func primary() throws -> Expr {
        if match([.FALSE]) { return Literal(value: false) }
        if match([.TRUE]) { return Literal(value: true) }
        if match([.NIL]) { return Literal(value: nil) }
        
        if match([.NUM, .STRING]) {
            return Literal(value: previous.literal)
        }
        
        if match([.IDENT]) {
            return Variable(name: previous)
        }
        
        if match([.LPAREN]) {
            let expr = try expression()
            try consume(.RPAREN, "Expect ')' after expression.")
            return Grouping(expression: expr)
        }
        throw error(peek, "Expected expression.")
    }
    
    //MARK: Helpers
    private func match(_ tokenTypes: [TokenType]) -> Bool {
        for t in tokenTypes {
            if check(t) {
                advance();
                return true
            }
        }
        return false
    }
    
    private func check(_ tokenType: TokenType) -> Bool {
        if isAtEnd { return false }
        return peek.tokenType == tokenType
    }
    
    @discardableResult
    private func advance() -> Token {
        if !isAtEnd { current += 1 }
        return previous
    }
    
    @discardableResult
    private func consume(_ tokenType: TokenType, _ message: String) throws -> Token {
        if check(tokenType) { return advance() }
        
        throw error(peek, message)
    }
    
    @discardableResult
    private func error(_ token: Token, _ message: String) -> ParserError {
        slox.error(token: token, message: message)
        return ParserError()
    }
    
    private func synchronize() {
        advance()
        
        while !isAtEnd {
            if previous.tokenType == .SEMICOLON { return }
            
            switch peek.tokenType {
            case .CLASS, .FOR, .FUN, .IF, .PRINT, .RETURN, .VAR, .WHILE: return
            default: break
            }
            
            advance()
        }
    }
}
