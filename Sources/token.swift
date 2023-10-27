import Foundation 

enum TokenType {
    case LPAREN, RPAREN, LBRACE, RBRACE, COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

    BANG, BANGEQ, EQ, EQEQ, GT, LT, GTEQ, LTEQ, 

    IDENT, STRING, NUM,

    AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR, PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE, BREAK,

    EOF 
}

struct Token {
    let tokenType: TokenType
    let lexeme: String
    let literal: Any?
    let line: UInt
}
