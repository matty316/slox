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

class Stmt {
	func accept<R>(visitor: any StmtVisitor) throws -> R? { return nil }
}

class Block: Stmt {
	let statements: [Stmt]
	init(statements: [Stmt]) {
		self.statements = statements
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitBlockStmt(stmt: self) as? R }
}

class Expression: Stmt {
	let expression: Expr
	init(expression: Expr) {
		self.expression = expression
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitExpressionStmt(stmt: self) as? R }
}

class If: Stmt {
	let condition: Expr
	let thenBranch: Stmt
	let elseBranch: Stmt?
	init(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?) {
		self.condition = condition
		self.thenBranch = thenBranch
		self.elseBranch = elseBranch
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitIfStmt(stmt: self) as? R }
}

class Print: Stmt {
	let expression: Expr
	init(expression: Expr) {
		self.expression = expression
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitPrintStmt(stmt: self) as? R }
}

class Var: Stmt {
	let name: Token
	let initializer: Expr?
	init(name: Token, initializer: Expr?) {
		self.name = name
		self.initializer = initializer
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitVarStmt(stmt: self) as? R }
}

class While: Stmt {
	let condition: Expr
	let body: Stmt
	init(condition: Expr, body: Stmt) {
		self.condition = condition
		self.body = body
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitWhileStmt(stmt: self) as? R }
}

class Break: Stmt {
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitBreakStmt(stmt: self) as? R }
}

class Function: Stmt {
	let name: Token
	let function: Fun
	init(name: Token, function: Fun) {
		self.name = name
		self.function = function
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitFunctionStmt(stmt: self) as? R }
}

class Return: Stmt {
	let keyword: Token
	let value: Expr?
	init(keyword: Token, value: Expr?) {
		self.keyword = keyword
		self.value = value
	}
	@discardableResult
	override func accept<R>(visitor: any StmtVisitor) throws -> R? { return try visitor.visitReturnStmt(stmt: self) as? R }
}

