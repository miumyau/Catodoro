import Foundation
import UIKit
let catodoroFontRegular = UIFont(name: "JosefinSlab", size: UIFont.systemFontSize)
let catodoroFontBold = UIFont(name: "JosefinSlab-Bold", size: UIFont.systemFontSize)
let catodoroFontRusRegular = UIFont(name: "AnonymousPro-Regular", size: UIFont.systemFontSize)
let catodoroFontRusBold = UIFont(name: "AnonymousPro-Bold", size: UIFont.systemFontSize)
var isSoundEnabled = true
var isVibrationEnabled = true
var sessionNumber = 5
var sessionDuration = 25
var shortRestDuration = 5
var longRestDuration = 15
var longRestTime = 3
var taskReadiness = false
var readinessNumber = 0
protocol TaskSelectionDelegate: AnyObject {
    func didSelectTask(_ task: TaskModel)
}

extension Notification.Name {
    static let didChangeBackgroundColor = Notification.Name("didChangeBackgroundColor")
    static let updateCatImage = Notification.Name("updateCatImage")
    static let updateReadinessImage = Notification.Name("updateReadinessImage")
    static let tasksDidUpdate = Notification.Name("tasksDidUpdate")
}

extension UIImage {
    // Метод для создания анимированного изображения из данных GIF
    static func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += frameDuration
                }
            }
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
}
extension MainViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            // Perform actions after the animation finishes, if necessary
        }
    }
}
extension Int{
    var degreesToRadians : CGFloat
    {return CGFloat(self) * .pi / 180}
}

extension UserDefaults {
    func setColor(color: UIColor?, forKey key: String) {
        guard let color = color else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(colorData, forKey: key)
        } catch {
            print("Ошибка при сохранении цвета: \(error)")
        }
    }
    
    func colorForKey(key: String) -> UIColor? {
        guard let colorData = data(forKey: key) else { return nil }
        
        do {
            if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
                return color
            }
        } catch {
            print("Ошибка при извлечении цвета: \(error)")
        }
        
        return nil
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}
extension CustomAlertViewController {
    // Определение массива durationOptions
    var sessionDurationOptions: [Int] {
        return [1, 5, 10, 15, 20, 25, 30,35,40,45,50,55,60] // Пример значений, вы можете изменить их по вашему усмотрению
    }
}

extension CustomAlertViewController {
    // Определение массива durationOptions
    var longRestDurationOptions: [Int] {
        return [ 5, 10, 15, 20, 25, 30,35,40,45,50,55,60] // Пример значений, вы можете изменить их по вашему усмотрению
    }
}

extension CustomAlertViewController {
    // Определение массива durationOptions
    var shortRestDurationOptions: [Int] {
        return [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20] // Пример
    }
}

extension CustomAlertViewController {
    // Определение массива sessionNumberOptions
    var sessionNumberOptions: [Int] {
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] // Пример значений, вы можете изменить их по вашему усмотрению
    }
    
    
}

extension CustomAlertViewController {
    // Определение массива sessionNumberOptions
    var restNumberOptions: [Int] {
        return [1, 2, 3, 4, 5, 6, 7, 8, 9] // Пример значений, вы можете изменить их по вашему усмотрению
    }
    
    
}

