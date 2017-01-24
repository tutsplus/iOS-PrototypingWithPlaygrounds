import UIKit
import XCPlayground
import GameplayKit // (1)

public extension UIImage { // (2)
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

let cardWidth = CGFloat(120) // (3)
let cardHeight = CGFloat(141)

public class Card: UIImageView { // (4)
    public let x: Int
    public let y: Int
    public init(image: UIImage?, x: Int, y: Int) {
        self.x = x
        self.y = y
        super.init(image: image)
        self.backgroundColor = .gray
        self.layer.cornerRadius = 10.0
        self.isUserInteractionEnabled = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class GameController: UIViewController {

    // (1): public variables so we can manipulate them in the playground
    public var padding = CGFloat(20) {
        didSet {
            resetGrid()
        }
    }

    public var backImage: UIImage = UIImage(
        color: .red,
        size: CGSize(width: cardWidth, height: cardHeight))!

    // (2): computed properties
    var viewWidth: CGFloat {
        get {
            return 4 * cardWidth + 5 * padding
        }
    }

    var viewHeight: CGFloat {
        get {
            return 4 * cardHeight + 5 * padding
        }
    }

    var shuffledNumbers = [Int]() // stores shuffled card numbers

    var firstCard: Card? // uncomment later

    public init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: viewWidth, height: viewHeight)
        shuffle()
        setupGrid()
        // uncomment later:
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(gr:)))
        view.addGestureRecognizer(tap)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.backgroundColor = .blue
        view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
    }

    // (3): Using GameplayKit API to generate a shuffling of the array [1, 1, 2, 2, ..., 8, 8]
    func shuffle() {
        let numbers = (1...8).flatMap{[$0, $0]}
        shuffledNumbers =
            GKRandomSource.sharedRandom().arrayByShufflingObjects(in: numbers) as! [Int]

    }

    // (4): Convert from card position on grid to index in the shuffled card numbers array
    func cardNumberAt(x: Int, _ y: Int) -> Int {
        assert(0 <= x && x < 4 && 0 <= y && y < 4)

        return shuffledNumbers[4 * x + y]
    }
    // (5): Position of card's center in superview
    func centerOfCardAt(x: Int, _ y: Int) -> CGPoint {
        assert(0 <= x && x < 4 && 0 <= y && y < 4)
        let (w, h) = (cardWidth + padding, cardHeight + padding)
        return CGPoint(
            x: CGFloat(x) * w + w/2 + padding/2,
            y: CGFloat(y) * h + h/2 + padding/2)

    }

    // (6): setup the subviews
    func setupGrid() {
        for i in 0..<4 {
            for j in 0..<4 {
                let n = cardNumberAt(x:i, j)
                let card = Card(image: UIImage(named: String(n)), x: i, y: j)
                card.tag = n
                card.center = centerOfCardAt(x:i, j)
                view.addSubview(card)
            }
        }
    }

    // (7): reset grid
    func resetGrid() {
        view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        for v in view.subviews {
            if let card = v as? Card {
                card.center = centerOfCardAt(x: card.x, card.y)
            }
        }
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        for v in view.subviews {
            if let card = v as? Card {     // (8): failable casting
                UIView.transition(
                    with: card,
                    duration: 1.0,
                    options: .transitionFlipFromLeft,
                    animations: {
                        card.image =  self.backImage
                    }, completion: nil)
            }
        }
    }

    func handleTap(gr: UITapGestureRecognizer) {
        let v = view.hitTest(gr.location(in: view), with: nil)!
        if let card = v as? Card {
            UIView.transition(
                with: card, duration: 0.5,
                options: .transitionFlipFromLeft,
                animations: {card.image = UIImage(named: String(card.tag))}) { // trailing completion handler:
                    _ in
                    card.isUserInteractionEnabled = false
                    if let pCard = self.firstCard {
                        if pCard.tag == card.tag {
                            UIView.animate(
                                withDuration: 0.5,
                                animations: {card.alpha = 0.0},
                                completion: {_ in card.removeFromSuperview()})
                            UIView.animate(
                                withDuration: 0.5,
                                animations: {pCard.alpha = 0.0},
                                completion: {_ in pCard.removeFromSuperview()})
                        } else {
                            UIView.transition(
                                with: card,
                                duration: 0.5,
                                options: .transitionFlipFromLeft,
                                animations: {card.image = self.backImage})
                            { _ in card.isUserInteractionEnabled = true }
                            UIView.transition(
                                with: pCard,
                                duration: 0.5,
                                options: .transitionFlipFromLeft,
                                animations: {pCard.image = self.backImage})
                            { _ in pCard.isUserInteractionEnabled = true }
                        }
                        self.firstCard = nil
                    } else {
                        self.firstCard = card
                    }
            }
        }
    }

    public func quickPeek() {
        for v in view.subviews {
            if let card = v as? Card {
                card.isUserInteractionEnabled = false
                UIView.transition(with: card, duration: 1.0, options: .transitionFlipFromLeft, animations: {card.image =  UIImage(named: String(card.tag))}) {
                    _ in
                    UIView.transition(with: card, duration: 1.0, options: .transitionFlipFromLeft, animations: {card.image =  self.backImage}) {
                        _ in
                        card.isUserInteractionEnabled = true
                    }

                }
            }
        }
    }

}
