import UIKit

final class GameViewController: UIViewController {
    private var game = Game()
    private let board = GameBoardView()
    private let roundLabel = UILabel()
    private let statusLabel = UILabel()
    private let statusArt = StatusArt()
    private let newRoundButton = UIButton(type: .system)
    private let xScore = ScoreView(title: "إكس", color: GameColor.violet, id: "scoreX")
    private let drawScore = ScoreView(title: "تعادل", color: GameColor.secondary, id: "scoreDraw")
    private let oScore = ScoreView(title: "أو", color: GameColor.teal, id: "scoreO")

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameColor.paper
        view.semanticContentAttribute = .forceRightToLeft
        board.onMove = { [weak self] index in self?.play(at: index) }
        newRoundButton.addTarget(self, action: #selector(beginRound), for: .touchUpInside)
        buildLayout()
        displayGame()
    }

    private func play(at index: Int) {
        guard game.play(at: index) else { return }
        displayGame()
        UIAccessibility.post(notification: .announcement, argument: statusLabel.text)
    }

    @objc private func beginRound() {
        guard game.state == .playing else {
            game.nextRound()
            displayGame()
            UIAccessibility.post(notification: .layoutChanged, argument: statusLabel)
            return
        }
        let alert = UIAlertController(title: "إعادة الجولة؟",
                                      message: "ستُمسح الحركات الحالية وتبقى نتائج الجلسة محفوظة.",
                                      preferredStyle: .alert)
        alert.view.tintColor = GameColor.violet
        alert.addAction(UIAlertAction(title: "متابعة اللعب", style: .cancel))
        alert.addAction(UIAlertAction(title: "إعادة الجولة", style: .destructive) { [weak self] _ in
            self?.game.restartRound()
            self?.displayGame()
            UIAccessibility.post(notification: .layoutChanged, argument: self?.statusLabel)
        })
        present(alert, animated: true)
    }

    private func displayGame() {
        roundLabel.text = "الجولة " + arabicNumber(game.roundNumber)
        switch game.state {
        case .playing:
            statusLabel.text = "دور " + game.currentPlayer.arabicName
            statusArt.show(game.currentPlayer, draw: false)
        case let .won(winner, _):
            statusLabel.text = "فاز " + winner.arabicName + "!"
            statusArt.show(winner, draw: false)
        case .draw:
            statusLabel.text = "انتهت بالتعادل"
            statusArt.show(nil, draw: true)
        }
        board.display(game)
        xScore.setScore(game.xWins)
        oScore.setScore(game.oWins)
        drawScore.setScore(game.draws)
        updateRoundButton()
    }

    private func updateRoundButton() {
        let finished = game.state != .playing
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 16
        config.baseBackgroundColor = finished ? GameColor.lime : GameColor.ink
        config.baseForegroundColor = finished ? GameColor.ink : .white
        config.title = finished ? "الجولة التالية" : "إعادة الجولة"
        config.image = UIImage(systemName: finished ? "arrow.left" : "arrow.counterclockwise")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { original in
            var edited = original
            edited.font = UIFont.preferredArabic(size: 17, weight: .bold, style: .headline)
            return edited
        }
        newRoundButton.configuration = config
        newRoundButton.accessibilityIdentifier = "newRound"
        newRoundButton.isEnabled = finished || game.board.contains { $0 != nil }
    }

    private func buildLayout() {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let canvas = UIView()
        canvas.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(canvas)

        let section = UIStackView()
        section.axis = .vertical
        section.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(section)
        let safe = view.safeAreaLayoutGuide
        let content = scroll.contentLayoutGuide
        let visible = scroll.frameLayoutGuide
        let width = section.widthAnchor.constraint(equalTo: canvas.widthAnchor, constant: -40)
        width.priority = .defaultHigh
        let fitHeight = canvas.heightAnchor.constraint(equalTo: visible.heightAnchor)
        fitHeight.priority = UILayoutPriority(249)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: safe.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
            scroll.leftAnchor.constraint(equalTo: safe.leftAnchor),
            scroll.rightAnchor.constraint(equalTo: safe.rightAnchor),
            canvas.topAnchor.constraint(equalTo: content.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            canvas.leftAnchor.constraint(equalTo: content.leftAnchor),
            canvas.rightAnchor.constraint(equalTo: content.rightAnchor),
            canvas.widthAnchor.constraint(equalTo: visible.widthAnchor),
            canvas.heightAnchor.constraint(greaterThanOrEqualTo: visible.heightAnchor),
            fitHeight, width,
            section.widthAnchor.constraint(lessThanOrEqualToConstant: 410),
            section.centerXAnchor.constraint(equalTo: canvas.centerXAnchor),
            section.centerYAnchor.constraint(equalTo: canvas.centerYAnchor),
            section.topAnchor.constraint(greaterThanOrEqualTo: canvas.topAnchor, constant: 15),
            section.bottomAnchor.constraint(lessThanOrEqualTo: canvas.bottomAnchor, constant: -15)
        ])
        let header = makeHeader()
        let status = makeStatus()
        let scores = makeScores()
        for item in [header, status, board, scores, newRoundButton] {
            section.addArrangedSubview(item)
        }
        section.setCustomSpacing(20, after: header)
        section.setCustomSpacing(12, after: status)
        section.setCustomSpacing(20, after: board)
        section.setCustomSpacing(14, after: scores)
        board.heightAnchor.constraint(equalTo: board.widthAnchor).isActive = true
        newRoundButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 49).isActive = true
    }

    private func makeHeader() -> UIView {
        let title = UILabel.arabic("Tic tac toe App", size: 38, weight: .heavy, style: .largeTitle)
        title.accessibilityTraits.insert(.header)
        let subtitle = UILabel.arabic("لاعبان على جهاز واحد", size: 14, weight: .medium, style: .subheadline)
        subtitle.textColor = GameColor.secondary
        let titles = UIStackView(arrangedSubviews: [title, subtitle])
        titles.axis = .vertical
        titles.spacing = 0
        let emblem = GameEmblem()
        let spacer = UIView()
        let header = UIStackView(arrangedSubviews: [emblem, spacer, titles])
        header.semanticContentAttribute = .forceLeftToRight
        header.alignment = .center
        header.spacing = 10
        NSLayoutConstraint.activate([
            emblem.widthAnchor.constraint(equalToConstant: 58),
            emblem.heightAnchor.constraint(equalTo: emblem.widthAnchor)
        ])
        return header
    }

    private func makeStatus() -> UIView {
        let panel = UIView()
        panel.backgroundColor = GameColor.ink
        panel.layer.cornerRadius = 20
        panel.layer.cornerCurve = .continuous
        roundLabel.font = .preferredArabic(size: 14, weight: .semibold, style: .subheadline)
        roundLabel.textColor = GameColor.lime
        roundLabel.accessibilityIdentifier = "roundNumber"
        statusLabel.font = .preferredArabic(size: 25, weight: .bold, style: .title2)
        statusLabel.textColor = .white
        statusLabel.accessibilityIdentifier = "gameStatus"
        for label in [roundLabel, statusLabel] {
            label.numberOfLines = 0
            label.textAlignment = .right
            label.adjustsFontForContentSizeCategory = true
        }
        let text = UIStackView(arrangedSubviews: [roundLabel, statusLabel])
        text.axis = .vertical
        text.translatesAutoresizingMaskIntoConstraints = false
        statusArt.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(text)
        panel.addSubview(statusArt)
        NSLayoutConstraint.activate([
            text.rightAnchor.constraint(equalTo: panel.rightAnchor, constant: -18),
            text.leftAnchor.constraint(equalTo: statusArt.rightAnchor, constant: 8),
            text.topAnchor.constraint(equalTo: panel.topAnchor, constant: 9),
            text.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -10),
            statusArt.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            statusArt.leftAnchor.constraint(equalTo: panel.leftAnchor, constant: 12),
            statusArt.widthAnchor.constraint(equalToConstant: 61),
            statusArt.heightAnchor.constraint(equalToConstant: 58),
            panel.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
        return panel
    }

    private func makeScores() -> UIView {
        let heading = UILabel.arabic("نتائج الجلسة", size: 16, weight: .bold, style: .headline)
        heading.accessibilityTraits.insert(.header)
        let rule = UIView()
        rule.backgroundColor = GameColor.rule
        let labelRow = UIStackView(arrangedSubviews: [rule, heading])
        labelRow.semanticContentAttribute = .forceLeftToRight
        labelRow.alignment = .center
        labelRow.spacing = 10
        heading.setContentHuggingPriority(.required, for: .horizontal)
        rule.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let values = UIStackView(arrangedSubviews: [oScore, drawScore, xScore])
        values.semanticContentAttribute = .forceLeftToRight
        values.distribution = .fillEqually
        values.spacing = 8
        let scores = UIStackView(arrangedSubviews: [labelRow, values])
        scores.axis = .vertical
        scores.spacing = 8
        return scores
    }
}

private let arabicDigits = Array("٠١٢٣٤٥٦٧٨٩")

private func arabicNumber(_ number: Int) -> String {
    String(String(number).map { digit in
        digit.wholeNumberValue.map { arabicDigits[$0] } ?? digit
    })
}

private extension UIFont {
    static func preferredArabic(size: CGFloat, weight: UIFont.Weight, style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }
}

private extension UILabel {
    static func arabic(_ text: String, size: CGFloat, weight: UIFont.Weight, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredArabic(size: size, weight: weight, style: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = GameColor.ink
        label.textAlignment = .right
        return label
    }
}

private final class ScoreView: UIView {
    private let number = UILabel()
    init(title: String, color: UIColor, id: String) {
        super.init(frame: .zero)
        backgroundColor = GameColor.tile
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.borderColor = GameColor.rule.cgColor
        layer.borderWidth = 1
        isAccessibilityElement = true
        accessibilityLabel = "نتيجة " + title
        accessibilityIdentifier = id
        let name = UILabel.arabic(title, size: 15, weight: .semibold, style: .subheadline)
        name.textColor = color
        number.font = .preferredArabic(size: 24, weight: .bold, style: .title2)
        number.textAlignment = .center
        number.adjustsFontForContentSizeCategory = true
        number.textColor = GameColor.ink
        let stack = UIStackView(arrangedSubviews: [number, name])
        stack.axis = .vertical
        stack.spacing = -4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            stack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -6)
        ])
    }

    required init?(coder: NSCoder) { fatalError("Use init(title:color:id:)") }

    func setScore(_ score: Int) {
        number.text = arabicNumber(score)
        accessibilityValue = number.text
    }
}

private final class GameEmblem: UIView {
    override func draw(_ rect: CGRect) {
        let side = bounds.width
        let tile = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.7, dy: 0.7), cornerRadius: 17)
        GameColor.lilac.setFill()
        tile.fill()
        let circle = UIBezierPath(ovalIn: CGRect(x: side * 0.48, y: side * 0.47,
                                                 width: side * 0.27, height: side * 0.27))
        GameColor.ink.setStroke()
        circle.lineWidth = 4
        circle.stroke()
        let cross = UIBezierPath()
        cross.move(to: CGPoint(x: side * 0.24, y: side * 0.25))
        cross.addLine(to: CGPoint(x: side * 0.43, y: side * 0.44))
        cross.move(to: CGPoint(x: side * 0.43, y: side * 0.25))
        cross.addLine(to: CGPoint(x: side * 0.24, y: side * 0.44))
        cross.lineWidth = 4.5
        cross.lineCapStyle = .round
        GameColor.violet.setStroke()
        cross.stroke()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }
}

private final class StatusArt: UIView {
    private var symbol = "multiply"
    private var accent = GameColor.lilac

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func show(_ player: Player?, draw: Bool) {
        symbol = draw ? "equal" : (player == .x ? "multiply" : "circle")
        accent = player == .o ? GameColor.mint : GameColor.lilac
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.translateBy(x: bounds.midX, y: bounds.midY)
        context.rotate(by: -0.12)
        let tile = CGRect(x: -19, y: -19, width: 38, height: 38)
        let shadow = UIBezierPath(roundedRect: tile.offsetBy(dx: 4, dy: 3), cornerRadius: 9)
        UIColor.white.withAlphaComponent(0.26).setStroke()
        shadow.lineWidth = 1.3
        shadow.stroke()
        accent.setFill()
        UIBezierPath(roundedRect: tile, cornerRadius: 9).fill()
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .heavy)
        if let image = UIImage(systemName: symbol, withConfiguration: config) {
            let size = image.size
            let icon = CGRect(x: -size.width / 2, y: -size.height / 2,
                              width: size.width, height: size.height)
            image.withTintColor(GameColor.ink, renderingMode: .alwaysOriginal).draw(in: icon)
        }
        context.restoreGState()
    }
}
