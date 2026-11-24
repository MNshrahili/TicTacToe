import UIKit

enum GameColor {
    static let paper = UIColor(red: 0.982, green: 0.969, blue: 0.940, alpha: 1)
    static let ink = UIColor(red: 0.157, green: 0.102, blue: 0.202, alpha: 1)
    static let secondary = UIColor(red: 0.370, green: 0.324, blue: 0.386, alpha: 1)
    static let rule = UIColor(red: 0.820, green: 0.794, blue: 0.784, alpha: 1)
    static let tile = UIColor(red: 1.000, green: 0.995, blue: 0.975, alpha: 1)
    static let violet = UIColor(red: 0.486, green: 0.239, blue: 0.733, alpha: 1)
    static let teal = UIColor(red: 0.035, green: 0.423, blue: 0.397, alpha: 1)
    static let lilac = UIColor(red: 0.925, green: 0.879, blue: 0.983, alpha: 1)
    static let mint = UIColor(red: 0.851, green: 0.934, blue: 0.878, alpha: 1)
    static let lime = UIColor(red: 0.865, green: 0.950, blue: 0.590, alpha: 1)
}

extension Player {
    var arabicName: String { self == .x ? "إكس" : "أو" }
    var ink: UIColor { self == .x ? GameColor.violet : GameColor.teal }
    var tint: UIColor { self == .x ? GameColor.lilac : GameColor.mint }
}

/// Board indices run left to right, from the top row to the bottom row.
final class GameBoardView: UIView {
    private let buttons = (0..<9).map { CellButton(index: $0) }
    var onMove: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = GameColor.rule
        layer.cornerRadius = 23
        layer.cornerCurve = .continuous
        clipsToBounds = true
        let rows = UIStackView()
        rows.axis = .vertical
        rows.distribution = .fillEqually
        rows.spacing = 2
        rows.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            rows.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            rows.leftAnchor.constraint(equalTo: leftAnchor, constant: 2),
            rows.rightAnchor.constraint(equalTo: rightAnchor, constant: -2)
        ])
        for row in 0..<3 {
            let line = UIStackView()
            line.semanticContentAttribute = .forceLeftToRight
            line.distribution = .fillEqually
            line.spacing = 2
            for column in 0..<3 {
                let button = buttons[row * 3 + column]
                button.addTarget(self, action: #selector(selectCell(_:)), for: .touchUpInside)
                line.addArrangedSubview(button)
            }
            rows.addArrangedSubview(line)
        }
        accessibilityElements = buttons
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func display(_ game: Game) {
        let winningCells: [Int]
        if case let .won(_, cells) = game.state {
            winningCells = cells
        } else {
            winningCells = []
        }
        for (index, button) in buttons.enumerated() {
            button.update(mark: game.board[index],
                          winning: winningCells.contains(index),
                          playing: game.state == .playing)
        }
    }

    @objc private func selectCell(_ sender: CellButton) { onMove?(sender.tag) }
}

private final class CellButton: UIButton {
    private var mark: Player?
    private var winning = false

    init(index: Int) {
        super.init(frame: .zero)
        tag = index
        accessibilityIdentifier = "cell\(index)"
        let rows = ["الأول", "الثاني", "الثالث"]
        let columns = ["الأيسر", "الأوسط", "الأيمن"]
        accessibilityLabel = "الصف \(rows[index / 3])، العمود \(columns[index % 3])"
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        // The outer corners trace the board; the inner corners retain its grid.
        switch index {
        case 0: roundOuterCorner(.layerMinXMinYCorner)
        case 2: roundOuterCorner(.layerMaxXMinYCorner)
        case 6: roundOuterCorner(.layerMinXMaxYCorner)
        case 8: roundOuterCorner(.layerMaxXMaxYCorner)
        default: break
        }
    }

    required init?(coder: NSCoder) { fatalError("Use init(index:)") }

    private func roundOuterCorner(_ corner: CACornerMask) {
        layer.cornerRadius = 21
        layer.maskedCorners = corner
    }

    func update(mark: Player?, winning: Bool, playing: Bool) {
        self.mark = mark
        self.winning = winning
        backgroundColor = winning ? mark?.ink : (mark?.tint ?? GameColor.tile)
        isEnabled = playing && mark == nil
        accessibilityValue = (mark?.arabicName ?? "فارغة") + (winning ? "، ضمن خط الفوز" : "")
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let side = min(bounds.width, bounds.height)
        guard let mark else {
            let dot = CGRect(x: bounds.midX - 2, y: bounds.midY - 2, width: 4, height: 4)
            GameColor.rule.setFill()
            UIBezierPath(ovalIn: dot).fill()
            return
        }
        let length = side * 0.39
        let box = CGRect(x: bounds.midX - length / 2, y: bounds.midY - length / 2,
                         width: length, height: length)
        let path: UIBezierPath
        if mark == .x {
            path = UIBezierPath()
            path.move(to: CGPoint(x: box.minX, y: box.minY))
            path.addLine(to: CGPoint(x: box.maxX, y: box.maxY))
            path.move(to: CGPoint(x: box.maxX, y: box.minY))
            path.addLine(to: CGPoint(x: box.minX, y: box.maxY))
        } else {
            path = UIBezierPath(ovalIn: box.insetBy(dx: -2, dy: -2))
        }
        (winning ? UIColor.white : mark.ink).setStroke()
        path.lineWidth = side * 0.074
        path.lineCapStyle = .round
        path.stroke()
    }
}
