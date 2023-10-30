protocol ExprVisitor<R> {
	associatedtype R
	func visitAssignExpr(expr: Assign) throws -> R?
	func visitBinaryExpr(expr: Binary) throws -> R?
	func visitCallExpr(expr: Call) throws -> R?
	func visitGroupingExpr(expr: Grouping) throws -> R?
	func visitLiteralExpr(expr: Literal) throws -> R?
	func visitLogicalExpr(expr: Logical) throws -> R?
	func visitUnaryExpr(expr: Unary) throws -> R?
	func visitVariableExpr(expr: Variable) throws -> R?
	func visitFunExpr(expr: Fun) throws -> R?
}

class Expr {
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return nil }
}

class Assign: Expr {
	let name: Token
	let value: Expr
	init(name: Token, value: Expr) {
		self.name = name
		self.value = value
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitAssignExpr(expr: self) as? R }
}

class Binary: Expr {
	let left: Expr
	let op: Token
	let right: Expr
	init(left: Expr, op: Token, right: Expr) {
		self.left = left
		self.op = op
		self.right = right
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitBinaryExpr(expr: self) as? R }
}

class Call: Expr {
	let callee: Expr
	let paren: Token
	let args: [Expr]
	init(callee: Expr, paren: Token, args: [Expr]) {
		self.callee = callee
		self.paren = paren
		self.args = args
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitCallExpr(expr: self) as? R }
}

class Grouping: Expr {
	let expression: Expr
	init(expression: Expr) {
		self.expression = expression
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitGroupingExpr(expr: self) as? R }
}

class Literal: Expr {
	let value: Any?
	init(value: Any?) {
		self.value = value
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitLiteralExpr(expr: self) as? R }
}

class Logical: Expr {
	let left: Expr
	let op: Token
	let right: Expr
	init(left: Expr, op: Token, right: Expr) {
		self.left = left
		self.op = op
		self.right = right
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitLogicalExpr(expr: self) as? R }
}

class Unary: Expr {
	let op: Token
	let right: Expr
	init(op: Token, right: Expr) {
		self.op = op
		self.right = right
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitUnaryExpr(expr: self) as? R }
}

class Variable: Expr {
	let name: Token
	init(name: Token) {
		self.name = name
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitVariableExpr(expr: self) as? R }
}

class Fun: Expr {
	let params: [Token]
	let body: [Stmt]
	init(params: [Token], body: [Stmt]) {
		self.params = params
		self.body = body
	}
	@discardableResult
	override func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitFunExpr(expr: self) as? R }
}

