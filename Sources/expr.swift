protocol ExprVisitor<R> {
	associatedtype R
	func visitAssignExpr(expr: Assign) throws -> R?
	func visitBinaryExpr(expr: Binary) throws -> R?
	func visitGroupingExpr(expr: Grouping) throws -> R?
	func visitLiteralExpr(expr: Literal) throws -> R?
	func visitLogicalExpr(expr: Logical) throws -> R?
	func visitUnaryExpr(expr: Unary) throws -> R?
	func visitVariableExpr(expr: Variable) throws -> R?
}

protocol Expr {
	func accept<R>(visitor: any ExprVisitor) throws -> R?
}

struct Assign: Expr {
	let name: Token
	let value: Expr
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitAssignExpr(expr: self) as? R }
}

struct Binary: Expr {
	let left: Expr
	let op: Token
	let right: Expr
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitBinaryExpr(expr: self) as? R }
}

struct Grouping: Expr {
	let expression: Expr
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitGroupingExpr(expr: self) as? R }
}

struct Literal: Expr {
	let value: Any?
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitLiteralExpr(expr: self) as? R }
}

struct Logical: Expr {
	let left: Expr
	let op: Token
	let right: Expr
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitLogicalExpr(expr: self) as? R }
}

struct Unary: Expr {
	let op: Token
	let right: Expr
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitUnaryExpr(expr: self) as? R }
}

struct Variable: Expr {
	let name: Token
	@discardableResult
	func accept<R>(visitor: any ExprVisitor) throws -> R? { return try visitor.visitVariableExpr(expr: self) as? R }
}

