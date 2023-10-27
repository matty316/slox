//
//  parser.swift
//
//
//  Created by matty on 10/23/23.
//

import Foundation

class Parser {
    enum ParserError: Error {
        case Generic
    }
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
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    func parse() -> [Stmt] {
        var statements = [Stmt]()
        
        while !isAtEnd {
            guard let declaration = declaration(isInLoop: false) else { return statements }
            statements.append(declaration)
        }
        
        return statements
    }
    
    private func declaration(isInLoop: Bool) -> Stmt? {
        do {
            if match([.VAR]) { return try varDeclaration() }
            return try statement(isInLoop: isInLoop)
        } catch {
            synchronize()
            return nil
        }
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
    
    private func statement(isInLoop: Bool) throws -> Stmt {
        if match([.FOR]) { return try forStatement() }
        if match([.IF]) { return try ifStatement(isInLoop: isInLoop) }
        if match([.PRINT]) { return try printStatement() }
        if match([.BREAK]) {
            if isInLoop {
                return try breakStatement()
            } else {
                throw self.error(previous, "cannot have break outside loop")
            }
        }
        if match([.WHILE]) { return try whileStatement() }
        if match([.LBRACE]) { return Block(statements: try block(isInLoop: isInLoop) )}
        return try expressionStatement()
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
        
        var body = try statement(isInLoop: true)
        
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
        
        return body
    }
    
    private func ifStatement(isInLoop: Bool) throws -> If {
        try consume(.LPAREN, "Expect '(' after 'if'")
        let condition = try expression()
        try consume(.RPAREN, "Expect ')' after 'if' condition")
        
        let thenBranch = try statement(isInLoop: isInLoop)
        var elseBranch: Stmt?
        if match([.ELSE]) {
            elseBranch = try statement(isInLoop: isInLoop)
        }
        
        return If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }
    
    private func printStatement() throws -> Print {
        let val = try expression()
        try consume(.SEMICOLON, "Expected a Semicolon")
        return Print(expression: val)
    }
    
    private func whileStatement() throws -> While {
        try consume(.LPAREN, "expected left paren")
        let condition = try expression()
        try consume(.RPAREN, "expected right paren")
        let stmt = try statement(isInLoop: true)
        return While(condition: condition, body: stmt)
    }
    
    private func block(isInLoop: Bool) throws -> [Stmt] {
        var stmts = [Stmt]()
        
        while !check(.RBRACE) && !isAtEnd {
            if let declaration = declaration(isInLoop: isInLoop) {
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
        
        return try primary()
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
        return ParserError.Generic
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
