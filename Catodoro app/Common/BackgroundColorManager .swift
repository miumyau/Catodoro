import UIKit
class BackgroundColorManager {
    static let shared = BackgroundColorManager()
    private(set) var currentColor: UIColor = .catodoroPink {
        didSet {
            NotificationCenter.default.post(name: .didChangeBackgroundColor, object: currentColor)
        }
    }
    func setColor(_ color: UIColor) {
        currentColor = color
    }
}

