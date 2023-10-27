protocol StmtVisitor<R> {
	associatedtype R
	func visitBlockStmt(stmt: Block) throws -> R?
	func visitExpressionStmt(stmt: Expression) throws -> R?
	func visitIfStmt(stmt: If) throws -> R?
	func visitPrintStmt(stmt: Print) throws -> R?
	func visitVarStmt(stmt: Var) throws -> R?
	func visitWhileStmt(stmt: While) throws -> R?
	func visitBreakStmt(stmt: Break) throws -> R?
	func visitFunctionStmt(stmt: Function) throws -> R?
	func visitReturnStmt(stmt: Return) throws -> R?
}

protocol Stmt {
	func accept<R>(visitor: any StmtVisitor) throws -> R?
}

struct Block: Stmt {
	let statements: [Stmt]
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitBlockStmt(stmt: self) as? R }
}

struct Expression: Stmt {
	let expression: Expr
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitExpressionStmt(stmt: self) as? R }
}

struct If: Stmt {
	let condition: Expr
	let thenBranch: Stmt
	let elseBranch: Stmt?
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitIfStmt(stmt: self) as? R }
}

struct Print: Stmt {
	let expression: Expr
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitPrintStmt(stmt: self) as? R }
}

struct Var: Stmt {
	let name: Token
	let initializer: Expr?
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitVarStmt(stmt: self) as? R }
}

struct While: Stmt {
	let condition: Expr
	let body: Stmt
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitWhileStmt(stmt: self) as? R }
}

struct Break: Stmt {
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitBreakStmt(stmt: self) as? R }
}

struct Function: Stmt {
	let name: Token
	let function: Fun
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitFunctionStmt(stmt: self) as? R }
}

struct Return: Stmt {
	let keyword: Token
	let value: Expr?
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitReturnStmt(stmt: self) as? R }
}

