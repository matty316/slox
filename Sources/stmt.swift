protocol StmtVisitor<R> {
	associatedtype R
	func visitBlockStmt(stmt: Block) throws -> R?
	func visitExpressionStmt(stmt: Expression) throws -> R?
	func visitPrintStmt(stmt: Print) throws -> R?
	func visitVarStmt(stmt: Var) throws -> R?
}

protocol Stmt {
	func accept<R>(visitor: any StmtVisitor) throws -> R?
}

struct Block: Stmt {
	var statements: [Stmt]
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitBlockStmt(stmt: self) as? R }
}

struct Expression: Stmt {
	let expression: Expr
	@discardableResult
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitExpressionStmt(stmt: self) as? R }
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

