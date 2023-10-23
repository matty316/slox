class Scanner {
    let input: String
    var tokens = [Token]()
    var start = 0
    var current = 0
    var line = 1

    init(input: String) {
        self.input = input
    }
}