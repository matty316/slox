protocol Visitor<R> {
	associatedtype R
	func visitBinaryExpr(expr: Binary) -> R?
	func visitGroupingExpr(expr: Grouping) -> R?
	func visitLiteralExpr(expr: Literal) -> R?
	func visitUnaryExpr(expr: Unary) -> R?
}

class Expr {
	func accept<R>(visitor: any Visitor) -> R? { return nil } 
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
	override func accept<R>(visitor: any Visitor) -> R? { return visitor.visitBinaryExpr(expr: self) as? R }

}

class Grouping: Expr {
	let expression: Expr
	init(expression: Expr) {
		self.expression = expression
	}
	override func accept<R>(visitor: any Visitor) -> R? { return visitor.visitGroupingExpr(expr: self) as? R }

}

class Literal: Expr {
	let value: Any?
	init(value: Any?) {
		self.value = value
	}
	override func accept<R>(visitor: any Visitor) -> R? { return visitor.visitLiteralExpr(expr: self) as? R }

}

class Unary: Expr {
	let op: Token
	let right: Expr
	init(op: Token,  right: Expr) {
		self.op = op
		self.right = right
	}
	override func accept<R>(visitor: any Visitor) -> R? { return visitor.visitUnaryExpr(expr: self) as? R }

}

