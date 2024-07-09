import UIKit
//класс для управления анимацией
class AnimationManager {
    static var currentStrokeEnd: CGFloat = 0.0
    static var isAnimationStarted = false
    static let foreProgressLayer = CAShapeLayer()
    static let animation = CABasicAnimation(keyPath: "strokeEnd")
    static var isResting = false
    static func startAnimation(duration: CFTimeInterval) {
        resetAnimation()
        foreProgressLayer.strokeEnd = 0.0
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.delegate = self as? CAAnimationDelegate
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        foreProgressLayer.add(animation, forKey: "strokeEnd")
        isAnimationStarted = true
    }
    // Метод для паузы анимации
    static func pausedAnimation() {
        let pausedTime = foreProgressLayer.convertTime(CACurrentMediaTime(), from: nil)
        foreProgressLayer.speed = 0.0
        foreProgressLayer.timeOffset = pausedTime
    }
    // Метод для возобновления анимации
    static func resumeAnimation() {
        let pausedTime = foreProgressLayer.timeOffset
        foreProgressLayer.speed = 1.0
        foreProgressLayer.timeOffset = 0.0
        foreProgressLayer.beginTime = 0.0
        let timeSincePaused = foreProgressLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        foreProgressLayer.beginTime = timeSincePaused
    }
    // Метод для остановки анимации
    static func stopAnimation() {
        foreProgressLayer.speed = 0.0
        foreProgressLayer.timeOffset = 0.0
        foreProgressLayer.beginTime = 0.0
        foreProgressLayer.strokeEnd = 0.0
        foreProgressLayer.removeAllAnimations()
        isAnimationStarted = false
    }
    // Сброс анимации
    static func resetAnimation() {
        foreProgressLayer.removeAllAnimations()
        foreProgressLayer.speed = 1.0
        foreProgressLayer.timeOffset = 0.0
        foreProgressLayer.beginTime = 0.0
        foreProgressLayer.strokeEnd = 0.0
        isAnimationStarted = false
    }
    // Метод для управления анимацикй
    static func startResumeAnimation(duration: CFTimeInterval) {
        if !isAnimationStarted {
            startAnimation(duration: duration)
        } else {
            resumeAnimation()
        }
    }
    //Рисуем круг
    static func drawForeLayer(color: String, catImage: UIImageView) {
        foreProgressLayer.path = UIBezierPath(arcCenter: CGPoint(x: catImage.frame.midX, y: catImage.frame.midY), radius: CGFloat(170), startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
        foreProgressLayer.strokeColor = UIColor(named: color)?.cgColor
        foreProgressLayer.fillColor = UIColor.clear.cgColor
        foreProgressLayer.lineWidth = 15
    }
    //Обновление анимации
    static func updateAnimation(time: Int, selectedTask: TaskModel?) {
        var sessionDuration: Double
        if isResting {
            if time == Int(selectedTask?.longRestDuration ?? 15) * 60 {
                sessionDuration = Double(selectedTask?.longRestDuration ?? 15) * 60
            } else if time == Int(selectedTask?.shortRestDuration ?? 5) * 60 {
                sessionDuration = Double(selectedTask?.shortRestDuration ?? 5) * 60
            } else {
                let currentRestTime = Double(time)
                if currentRestTime < Double(selectedTask?.shortRestDuration ?? 5) * 60 {
                    sessionDuration = Double(selectedTask?.shortRestDuration ?? 5) * 60
                } else {
                    sessionDuration = Double(selectedTask?.longRestDuration ?? 15) * 60
                }
            }
        } else {
            sessionDuration = Double(selectedTask?.sessionDuration ?? 25) * 60
        }
        let progress = 1 - Double(time) / sessionDuration
        let targetStrokeEnd = 1 - CGFloat(time) / CGFloat(sessionDuration)
        foreProgressLayer.strokeEnd = CGFloat(progress)
        // Плавное обновление strokeEnd
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        // Синхронизируем начальное значеанние имации с текущим значением strokeEnd
        animation.fromValue = foreProgressLayer.presentation()?.strokeEnd ?? 0.0
        animation.toValue = targetStrokeEnd
        animation.duration = 0.5 // Продолжительность анимации (в секундах)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        foreProgressLayer.add(animation, forKey: "strokeAnimation")
        // Установка нового значения strokeEnd без анимации
        currentStrokeEnd = targetStrokeEnd
        
    }
}
