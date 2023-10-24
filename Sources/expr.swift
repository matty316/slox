protocol Visitor<R> {
	associatedtype R
	func visitBinaryExpr(expr: Binary) throws -> R?
	func visitGroupingExpr(expr: Grouping) throws -> R?
	func visitLiteralExpr(expr: Literal) throws -> R?
	func visitUnaryExpr(expr: Unary) throws -> R?
}

class Expr {
	func accept<R>(visitor: any Visitor) throws -> R? { return nil } 
}

class Binary: Expr {
	let left: Expr
	let op: Token
	let right: Expr
	init(left: Expr,  op: Token,  right: Expr) {
		self.left = left
		self.op = op
		self.right = right
	}
	override func accept<R>(visitor: any Visitor) throws -> R? { return try visitor.visitBinaryExpr(expr: self) as? R }

}

class Grouping: Expr {
	let expression: Expr
	init(expression: Expr) {
		self.expression = expression
	}
	override func accept<R>(visitor: any Visitor) throws -> R? { return try visitor.visitGroupingExpr(expr: self) as? R }

}

class Literal: Expr {
	let value: Any?
	init(value: Any?) {
		self.value = value
	}
	override func accept<R>(visitor: any Visitor) throws -> R? { return try visitor.visitLiteralExpr(expr: self) as? R }

}

class Unary: Expr {
	let op: Token
	let right: Expr
	init(op: Token,  right: Expr) {
		self.op = op
		self.right = right
	}
	override func accept<R>(visitor: any Visitor) throws -> R? { return try visitor.visitUnaryExpr(expr: self) as? R }

}

