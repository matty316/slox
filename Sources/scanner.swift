import Foundation

class Scanner {
    let input: String
    var tokens = [Token]()
    var start: String.Index
    var current: String.Index
    var line: UInt = 1
    
    static var keywords: [String: TokenType] {
        [
            "and": .AND,
            "class": .CLASS,
            "else": .ELSE,
            "false": .FALSE,
            "for": .FOR,
            "fun": .FUN,
            "if": .IF,
            "nil": .NIL,
            "or": .OR,
            "print": .PRINT,
            "return": .RETURN,
            "super": .SUPER,
            "this": .THIS,
            "true": .TRUE,
            "var": .VAR,
            "while": .WHILE,
        ]
    }
    
    var isAtEnd: Bool {
        current >= input.endIndex
    }
    
    init(input: String) {
        self.input = input
        self.current = input.startIndex
        self.start = input.startIndex
    }
    
    func scanTokens() -> [Token] {
        while !isAtEnd {
            start = current
            scanToken()
        }
        
        tokens.append(Token(tokenType: .EOF, lexeme: "", literal: nil, line: line))
        return tokens
    }
    
    func scanToken() {
        let c = advance()
        
        switch c {
        case "(": addToken(.LPAREN)
        case ")": addToken(.RPAREN)
        case "{": addToken(.LBRACE)
        case "}": addToken(.RBRACE)
        case ",": addToken(.COMMA)
        case ".": addToken(.DOT)
        case "-": addToken(.MINUS)
        case "+": addToken(.PLUS)
        case ";": addToken(.SEMICOLON)
        case "*": addToken(.STAR)
        case "!": addToken(match(expected: "=") ? .BANGEQ : .BANG)
        case "=": addToken(match(expected: "=") ? .EQEQ : .EQ)
        case "<": addToken(match(expected: "=") ? .LTEQ : .LT)
        case ">": addToken(match(expected: "=") ? .GTEQ : .GT)
        case "/":
            if match(expected: "/") {
                while peek() != "\n" && !isAtEnd { advance() }
            } else if match(expected: "*") {
                while peek() != "*" && peekNext() != "/" && !isAtEnd { advance() }
                advance()
                advance()
            } else {
                addToken(.SLASH)
            }
        case " ": break
        case "\t": break
        case "\r": break
        case "\n": line += 1
        case "\"": string()
        default:
            if isDigit(c) {
                number()
            } else if isAlpha(c) {
                identifier()
            } else {
                slox.error(line: line, message: "Unexpected Char")
            }
            break
        }
    }
    
    //MARK: Helpers
    @discardableResult
    func advance() -> Character {
        let cur = current
        current = input.index(after: current)
        return input[cur]
    }
    
    func addToken(_ tokenType: TokenType) {
        addToken(tokenType, nil)
    }
    
    func addToken(_ tokenType: TokenType, _ literal: Any?) {
        let text = String(input[start..<current]);
        tokens.append(Token(tokenType: tokenType, lexeme: text, literal: literal, line: line))
    }
    
    func isDigit(_ c: Character) -> Bool {
        return "0" <= c && c <= "9"
    }
    
    func isAlpha(_ c: Character) -> Bool {
        return "a" <= c && c <= "z" || "A" <= c && c <= "Z" || c == "_"
    }
    
    func isAlphaNumeric(_ c: Character) -> Bool {
        return isAlpha(c) || isDigit(c)
    }
    
    func match(expected: Character) -> Bool {
        if isAtEnd { return false }
        if input[current] != expected { return false }
        
        current = input.index(after: current)
        return true
    }
    
    func peek() -> Character {
        if isAtEnd { return "\0" }
        return input[current]
    }
    
    func peekNext() -> Character {
        if input.index(after: current) >= input.endIndex { return "\0" }
        return input[input.index(after: current)]
    }
    
    func string() {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            advance()
        }
        
        if isAtEnd {
            slox.error(line: line, message: "Unterminated string")
        }
        
        advance()
        
        let startIdx = input.index(after: start)
        let endIdx = input.index(before: current)
        let val = String(input[startIdx..<endIdx])
        addToken(.STRING, val)
    }
    
    func number() {
        while isDigit(peek()) { advance() }
        
        if peek() == "." && isDigit(peekNext()) {
            advance()
            
            while isDigit(peek()) { advance() }
        }
        
        addToken(.NUM, Double(String(input[start..<current])))
    }
    
    func identifier() {
        while isAlphaNumeric(peek()) { advance() }
        
        let text = String(input[start..<current])
        guard let keyword = Scanner.keywords[text] else {
            addToken(.IDENT)
            return
        }
        addToken(keyword)
    }
}
