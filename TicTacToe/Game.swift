enum Player: String {
    case x = "X"
    case o = "O"

    var other: Player { self == .x ? .o : .x }
}

enum RoundState: Equatable {
    case playing
    case won(Player, [Int])
    case draw
}

struct Game {
    private static let winningLines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
        [0, 4, 8], [2, 4, 6]              // Diagonals
    ]

    private(set) var board = [Player?](repeating: nil, count: 9)
    private(set) var currentPlayer = Player.x
    private(set) var state = RoundState.playing
    private(set) var roundNumber = 1
    private(set) var xWins = 0
    private(set) var oWins = 0
    private(set) var draws = 0

    @discardableResult
    mutating func play(at index: Int) -> Bool {
        guard state == .playing, board.indices.contains(index),
              board[index] == nil else { return false }

        board[index] = currentPlayer
        if let line = Self.winningLines.first(where: { line in
            line.allSatisfy { board[$0] == currentPlayer }
        }) {
            state = .won(currentPlayer, line)
            if currentPlayer == .x { xWins += 1 } else { oWins += 1 }
        } else if board.allSatisfy({ $0 != nil }) {
            state = .draw
            draws += 1
        } else {
            currentPlayer = currentPlayer.other
        }
        return true
    }

    mutating func nextRound() {
        guard state != .playing else { return }
        roundNumber += 1
        state = .playing
        restartRound()
    }

    mutating func restartRound() {
        guard state == .playing else { return }
        currentPlayer = roundNumber.isMultiple(of: 2) ? .o : .x
        board = [Player?](repeating: nil, count: 9)
    }
}
