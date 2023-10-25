// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

@main
struct slox: ParsableCommand {
    static var hadError = false
    static var hadRuntimeError = false
    private static let interpreter = Interpreter()
    
    @Argument(help: "enter a filename")
    var filename: String?
    
    mutating func run() throws {
        if let filename = filename {
            runFile(filename: filename)
        } else {
            runPrompt()
        }
    }
    
    func runPrompt() {
        print("Welcome to hell")
        while true {
            print("> ", terminator: "")
            
            guard let line = readLine() else {
                return
            }
            
            let s = Scanner(input: line)
            let tokens = s.scanTokens()
            let p = Parser(tokens: tokens)
            if let stmt = p.parse().first {
                Self.interpreter.interpretStmt(statement: stmt)
            }
            Self.hadError = false
        }
    }
    
    func runFile(filename: String) {
        let url = URL(fileURLWithPath: filename)
        do {
            let input = try String(contentsOf: url, encoding: .utf8)
            runString(input: input)
            if Self.hadError { Self.exit(withError: ExitCode(65)) }
            if Self.hadRuntimeError { Self.exit(withError: ExitCode(70)) }
        } catch {
            print(error)
        }
    }
    
    func runString(input: String) {
        let s = Scanner(input: input)
        let tokens = s.scanTokens()
        
        let p =  Parser(tokens: tokens)
        let stmts = p.parse()
        
        if Self.hadError { return }

        Self.interpreter.interpret(statements: stmts)
    }
    
    static func error(line: UInt, message: String) {
        report(line: line, where: "", message: message)
    }
    
    static func error(token: Token, message: String) {
        if token.tokenType == .EOF {
            report(line: token.line, where: " at end", message: message)
        } else {
            report(line: token.line, where: " at '" + token.lexeme + "'", message: message)
        }
    }
    
    static func runtimeError(_ error: RuntimeError) {
        print("\(error.message) \n[line \(error.token.line)]")
        hadRuntimeError = true
    }
    
    private static func report(line: UInt, where: String, message: String) {
        print("[line \(line)] Error \(`where`): \(message)")
        hadError = true
    }
}
