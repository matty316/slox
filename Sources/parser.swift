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
    
    func parse() -> Expr? {
        do {
            return try expression()
        } catch {
            return nil
        }
    }
    
    private func expression() throws -> Expr {
        return try equality()
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
