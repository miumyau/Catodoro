import UIKit
import UserNotifications
class TimerManager {
    // Замыкание для обновления состояния
    var stateDidChange: ((Bool) -> Void)?// Замыкание для обновления состояния
    // Внутреннее состояние для отдыха
    private var isRestingInternal = false {
        didSet {
            // Вызываем замыкание при изменении состояния
            stateDidChange?(isRestingInternal)
        }
    }
    // Свойство для внешнего доступа к состоянию отдыха
    var isResting: Bool {
        return isRestingInternal
    }
    //Свойства дял управления таймером
    var timer = Timer()
    var time: Int
    var isTimerStarted = false
    var isSessionStarted = false
    //экземпляр класса SoundManager для вызова его функций
    var soundManager: SoundManager?
    //выбранная задача
    private var selectedTask: TaskModel? {
        didSet {
            sessionNumber = Int(selectedTask?.sessionNumber ?? 0)//устанавливаем sessionNumber равным значению выбранной задачи
        }
    }
    // UI элементы
    var  catImage: UIImageView!
    var readinessPanel: UIView!
    var readinessStackView: UIStackView!
    weak var view: UIView!
    weak var timeLabel: UILabel!
    weak var bannerLabel: UILabel!
    weak var motivationLabel: UILabel!
    weak var startButton: UIButton!
    weak var optionsButton: UIButton!
    weak var stopButton: UIButton!
    weak var pauseImage: UIImageView!
    weak var circlePauseLayer: CAShapeLayer!
    //массивы изображений
    let catImages: [String] = ["cat1", "cat2", "cat3", "cat4", "cat5"]
    let readyImages: [String] = ["fishReady", "bugReady", "mushReady"]
    let notreadyImages: [String] = ["fishNotReady", "bugNotReady", "mushNotReady"]
    //индексы
    var currentreadyIndex: Int
    var sessionNumber: Int
    // Инициализатор класса
    init(view: UIView, readinessStackView: UIStackView, catImage: UIImageView, readinessPanel: UIView, currentreadyIndex: Int, timeLabel: UILabel, isRestingInternal: Bool, isSessionStarted: Bool, isTimerStarted: Bool, motivationLabel: UILabel, bannerLabel: UILabel, startButton: UIButton, optionsButton: UIButton, stopButton: UIButton, pauseImage: UIImageView, circlePauseLayer: CAShapeLayer, soundManager: SoundManager?, time: Int) {
        self.view = view
        self.isRestingInternal = isRestingInternal
        self.isSessionStarted = isSessionStarted
        self.isTimerStarted = isTimerStarted
        self.timeLabel = timeLabel
        self.startButton = startButton
        self.stopButton = stopButton
        self.pauseImage = pauseImage
        self.circlePauseLayer = circlePauseLayer
        self.optionsButton = optionsButton
        self.readinessPanel = readinessPanel
        self.readinessStackView = readinessStackView
        self.currentreadyIndex = currentreadyIndex
        self.bannerLabel = bannerLabel
        self.motivationLabel = motivationLabel
        self.catImage = catImage
        self.soundManager = soundManager
        self.time = time
        self.sessionNumber = 0
        
        // Подписываемся на уведомления об обновлении изображений готовности
        NotificationCenter.default.addObserver(self, selector: #selector(updateReadinessImage), name: .updateReadinessImage, object: nil)
    }
    // Деинициализатор, отписываемся от уведомлений
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // Метод для запуска таймера
    func startTimer() {
        circlePauseLayer.removeFromSuperlayer()
        pauseImage.removeFromSuperview()
        timer.invalidate() // Останавливаем предыдущий таймер, если он был запущен
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        isTimerStarted = true
        updateTimer() // Немедленно вызываем обновление таймера, чтобы синхронизировать отображение времени
    }
    // Метод для приостановки таймера
    func pauseTimer() {
        if isTimerStarted {
            AnimationManager.pausedAnimation()
            timer.invalidate()
            isTimerStarted=false
            let circlePausePath = UIBezierPath(arcCenter: CGPoint(x: view.frame.midX, y: view.frame.midY-130), radius: CGFloat(170), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
            circlePauseLayer.path = circlePausePath.cgPath
            circlePauseLayer.fillColor = UIColor.white.cgColor
            circlePauseLayer.opacity=0.5
            circlePauseLayer.strokeColor = UIColor.clear.cgColor
            view.layer.addSublayer(circlePauseLayer)
            view.addSubview(pauseImage)
            pauseImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                pauseImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 260),
                pauseImage.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
            startButton.setTitle("Вернуться", for: .normal)
            stopButton.setTitle("Отменить", for: .normal)
            stopButton.backgroundColor = .catodoroRed
        }
    }
    // Метод для возобновления таймера
    func resumeTimer() {
        startTimer()
        AnimationManager.resumeAnimation()
        startButton.setTitle("Пауза", for: .normal)
        stopButton.setTitle("Отменить", for: .normal)
        stopButton.backgroundColor = .catodoroRed
    }
    // Метод для остановки таймера
    func stopTimer() {
        circlePauseLayer.removeFromSuperlayer()
        pauseImage.removeFromSuperview()
        timer.invalidate()
        isTimerStarted = false
        AnimationManager.stopAnimation()
    }
    // Метод для сброса таймера
    func resetTimer() {
        time = 0
        isTimerStarted = false
        isSessionStarted = false
        circlePauseLayer.removeFromSuperlayer()
        pauseImage.removeFromSuperview()
        timeLabel.text = formatTime(time: time)
        startButton.setTitle("Старт", for: .normal)
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
        startButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        stopButton.setTitle("Отменить", for: .normal)
        stopButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        AnimationManager.resetAnimation()
    }
    // Метод для форматирования времени в строку "мм:сс"
    func formatTime(time: Int) -> String {
        let minutes = time / 60 % 60
        let seconds = time % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    // Обновление таймера
    @objc  func updateTimer() {
        guard let task = selectedTask else { return }
        if time < 1 {
            if isResting {
                startWorkSession()
            } else {
                task.readinessNumber += 1
                changeImage(imageIndex: Int(task.readinessNumber) - 1)
                saveContext() // Сохранение после изменения readinessNumber
                // Проверка завершения всех сессий
                if task.readinessNumber >= task.sessionNumber {
                    // Завершение задачи
                    if task.canNotify {
                        // Отправка уведомления о завершении задачи
                        scheduleNotification(title: "Задача завершена", body: "Поздравляем! Вы завершили задачу.", identifier: "taskCompletionNotification")
                    }
                    AnimationManager.stopAnimation()
                    task.taskReadiness = true
                    // Сохранение после завершения задачи
                    saveContext()
                    // Обновляем кнопку выбора задачи
                    optionsButton.setTitle("Выберите задачу", for: .normal)
                    showCompletionOverlay()
                    stopTimer()
                    resetTimer()
                    clearReadinessPanel()
                    setupInitialState()
                    return // Выход из функции, чтобы не начинать новую сессию
                }
                if Int(task.readinessNumber) % longRestTime == 0 {
                    if task.canNotify {
                        // Отправка уведомления о начале длинного отдыха
                        scheduleNotification(title: "Длинный отдых😌", body: "Время для длинного отдыха", identifier: "longRestNotification")
                    }
                    startLongRest()
                } else {
                    if task.canNotify {
                        // Отправка уведомления о начале короткого отдыха
                        scheduleNotification(title: "Короткий отдых😌", body: "Время для короткого отдыха", identifier: "shortRestNotification")
                    }
                    startShortRest()
                }
            }
        } else {
            time -= 1 // Уменьшаем время каждую секунду
            timeLabel.text = formatTime(time: time)
            AnimationManager.updateAnimation(time: time, selectedTask: selectedTask)
        }
    }
    
    // Метод для начала рабочей сессии
    func startWorkSession() {
        guard let task = selectedTask else {
            print("selectedTask is nil")
            return
        }
        if let soundManager = soundManager {
            soundManager.playSound(fileName: "mew", type: "mp3", isRepeated: false)
        } else {
            print("soundManager is nil")
        }
        
        if task.canNotify {
            // Отправка уведомления о начале длинного отдыха
            print("\(task.canNotify)")
            scheduleNotification(title: "За дело!⏰", body: "Начало рабочей сессии", identifier: "WorkSessionNotification")
        }
        isRestingInternal = false
        motivationLabel.text="За дело!"
        isSessionStarted = true
        time = Int(task.sessionDuration) * 60
        startButton.setTitle("Пауза", for: .normal)
        startButton.backgroundColor = .catodoroMidGreen
        stopButton.backgroundColor = .catodoroRed
        AnimationManager.drawForeLayer(color: "CatodoroGreen", catImage: catImage)
        AnimationManager.foreProgressLayer.strokeEnd = 0
        startTimer()
        DispatchQueue.main.async { [self] in
            AnimationManager.startAnimation(duration: CFTimeInterval(time))
        }
    }
    
    // Метод для начала короткого отдыха
    func startShortRest() {
        guard let task = selectedTask else { return }
        if let soundManager = soundManager {
            soundManager.playSound(fileName: "rrrrr", type: "mp3", isRepeated: false)
        } else {
            print("soundManager is nil")
        }
        timeLabel.text="\(task.shortRestDuration):00"
        motivationLabel.text="Отдыхай😌"
        time = Int(task.shortRestDuration) * 60
        isRestingInternal = true
        AnimationManager.drawForeLayer(color: "CatodoroRed", catImage: catImage)
        AnimationManager.foreProgressLayer.strokeEnd = 0 // Устанавливаем начальное значение strokeEnd в 0
        startTimer() // Запускаем таймер
        DispatchQueue.main.async { [self] in
            AnimationManager.startAnimation(duration: CFTimeInterval(time))
        }
        startButton.setTitle("Пропустить", for: .normal)
        
        
    }
    // Метод для начала длинного отдыха
    func startLongRest() {
        guard let task = selectedTask else { return }
        if let soundManager = soundManager {
            soundManager.playSound(fileName: "rrrrr", type: "mp3", isRepeated: false)
        } else {
            print("soundManager is nil")
        }
        motivationLabel.text="Отдыхай😌"
        timeLabel.text="\(task.longRestDuration):00"
        time = Int(task.longRestDuration) * 60
        isRestingInternal = true
        AnimationManager.drawForeLayer(color: "CatodoroDarkPurp", catImage: catImage)
        AnimationManager.foreProgressLayer.strokeEnd = 0 // Устанавливаем начальное значение strokeEnd в 0
        startTimer() // Запускаем таймер
        DispatchQueue.main.async { [self] in
            AnimationManager.startAnimation(duration: CFTimeInterval(time))
        }// Запускаем анимацию с правильной длительностью
        startButton.setTitle("Пропустить", for: .normal)
    }
    
    // Уведомления
    func scheduleNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Ошибка добавления уведомления: \(error.localizedDescription)")
            }
        }
    }
    // Метод для показа оверлея завершения задачи
    func showCompletionOverlay() {
        stopButton.isEnabled = false
        circlePauseLayer.removeFromSuperlayer()
        pauseImage.removeFromSuperview()
        if let soundManager = soundManager {
            soundManager.playSound(fileName: "happysound", type: "mp3", isRepeated: true)
        } else {
            print("soundManager is nil")
        }
        
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        view.addSubview(overlayView)
        
        let gifImageView = UIImageView(frame: CGRect(x: overlayView.frame.midX - 90, y: overlayView.frame.midY - 30, width: 150, height: 200))
        gifImageView.center = CGPoint(x: gifImageView.center.x, y: gifImageView.center.y)
        
        if let gifURL = Bundle.main.url(forResource: "cat-dance-funny", withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL) {
            gifImageView.image = UIImage.gifImageWithData(gifData)
        }
        overlayView.addSubview(gifImageView)
        
        bannerLabel.frame = CGRect(x: view.bounds.midX - view.bounds.width / 2, y: view.bounds.midY - 100, width: view.bounds.width, height: 100)
        bannerLabel.text = "Ура!\nТы молодец!"
        bannerLabel.font = UIFont(name: "AnonymousPro-Regular", size: 40)
        bannerLabel.numberOfLines = 2
        bannerLabel.lineBreakMode = .byWordWrapping
        bannerLabel.textAlignment = .center
        bannerLabel.textColor = .catodoroBlack
        view.addSubview(bannerLabel)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay(_:)))
        overlayView.addGestureRecognizer(tapGesture)
        startButton.setTitle("Старт", for: .normal)
        startButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        stopButton.setTitle("Стоп", for: .normal)
        stopButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        isTimerStarted = false
        AnimationManager.resetAnimation()
    }
    // Метод скрытия слоя готовности
    @objc  func dismissOverlay(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
        bannerLabel.removeFromSuperview()
        if let soundManager = soundManager {
            soundManager.stopSound()
        } else {
            print("soundManager is nil")
        }
        
    }
    // Метод для обновления готовности задачи и сохранения в CoreData
    func updateTaskReadiness(task: TaskModel) {
        saveContext()
    }
    // Метод для сохранения данных в CoreData
    func saveContext() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        do {
            try context.save()
            print("Изменения сохранены в контексте.")
        } catch {
            print("Ошибка сохранения контекста: \(error.localizedDescription)")
        }
    }
    
    // Метод для для изменения изображения готовности
    func changeReadinessImages() {
        _ = readyImages[currentreadyIndex]
        let notReadyImageName = notreadyImages[currentreadyIndex]
        
        var imageIndex = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                for imageView in row.arrangedSubviews {
                    if let imageView = imageView as? UIImageView {
                        imageView.image = UIImage(named: notReadyImageName) // Меняем на не готовое изображение
                    }
                    imageIndex += 1
                }
            }
        }
    }
    // Метод для изменения изображения на цветное
    func changeImage(imageIndex: Int) {
        guard imageIndex < catImages.count else { return }
        // Проверяем, что imageIndex не выходит за пределы количества изображений
        var totalImages = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                totalImages += row.arrangedSubviews.count
            }
        }
        if imageIndex >= totalImages {
            return // Если индекс недопустим, выходим из метода
        }
        var currentIndex = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                for imageView in row.arrangedSubviews {
                    if currentIndex == imageIndex, let imageView = imageView as? UIImageView {
                        // Меняем изображение на "готовое" из массива readyImages
                        imageView.image = UIImage(named: readyImages[currentreadyIndex])
                        return
                    }
                    currentIndex += 1
                }
            }
        }
    }
    
    // Обновление панели готовности
    func updateReadinessPanel(sessionNumber: Int) {
        // Удаляем все существующие подвиды из readinessStackView
        readinessStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxImagesPerRow = 5
        var currentHorizontalStackView = UIStackView()
        currentHorizontalStackView.axis = .horizontal
        currentHorizontalStackView.alignment = .center
        currentHorizontalStackView.distribution = .fillEqually
        currentHorizontalStackView.spacing = 3
        for i in 0..<sessionNumber {
            if i % maxImagesPerRow == 0 && i != 0 {
                readinessStackView.addArrangedSubview(currentHorizontalStackView)
                currentHorizontalStackView = UIStackView()
                currentHorizontalStackView.axis = .horizontal
                currentHorizontalStackView.alignment = .center
                currentHorizontalStackView.distribution = .fillEqually
                currentHorizontalStackView.spacing = 3
            }
            let readyImage = UIImageView(image: UIImage(named: notreadyImages[currentreadyIndex]))
            readyImage.contentMode = .scaleAspectFit
            readyImage.translatesAutoresizingMaskIntoConstraints = false
            readyImage.heightAnchor.constraint(equalToConstant: 50).isActive = true
            readyImage.widthAnchor.constraint(equalToConstant: 50).isActive = true
            currentHorizontalStackView.addArrangedSubview(readyImage)
        }
        readinessStackView.addArrangedSubview(currentHorizontalStackView)
        // Увеличиваем высоту панели в зависимости от количества строк
        let numberOfRows = (sessionNumber + maxImagesPerRow - 1) / maxImagesPerRow
        let panelHeight = CGFloat(numberOfRows * 55)
        // Удаляем все старые ограничения по высоте, если они есть
        readinessPanel.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                readinessPanel.removeConstraint(constraint)
            }
        }
        
        let newHeightConstraint = readinessPanel.heightAnchor.constraint(equalToConstant: panelHeight)
        newHeightConstraint.isActive = true
        // Устанавливаем верхнее ограничение панели
        readinessPanel.superview?.constraints.forEach { constraint in
            if constraint.firstAttribute == .top && constraint.firstItem as? UIView == readinessPanel {
                readinessPanel.superview?.removeConstraint(constraint)
            }
        }
        
        let newTopConstraint = readinessPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: sessionNumber > 5 ? 650 : 670)
        newTopConstraint.isActive = true
        
        // Принудительно обновляем расположение панели с анимацией
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // Обновление изображения готовности
    @objc  func updateReadinessImage(notification: Notification) {
        if let userInfo = notification.userInfo, let currentreadyIndex = userInfo["currentreadyIndex"] as? Int {
            self.currentreadyIndex = currentreadyIndex
            // Обновление изображений на панели готовности
            updateReadinessPanel(sessionNumber: sessionNumber)
        }
    }
    
    //Обновление готовности
    func updateReadiness(imageIndex: Int) {
        // Проверяем, что imageIndex не выходит за пределы количества изображений
        var totalImages = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                totalImages += row.arrangedSubviews.count
            }
        }
        if imageIndex >= totalImages {
            return // Если индекс недопустим, выходим из метода
        }
        var currentIndex = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                for imageView in row.arrangedSubviews {
                    if currentIndex == imageIndex, let imageView = imageView as? UIImageView {
                        // Меняем изображение на "готовое" из массива readyImages
                        imageView.image = UIImage(named: readyImages[currentreadyIndex])
                        return
                    }
                    currentIndex += 1
                }
            }
        }
    }
    
    //Очистка изображения готовности
    func clearImage() {
        var imageIndex = 0
        for rowStackView in readinessStackView.arrangedSubviews {
            if let row = rowStackView as? UIStackView {
                for imageView in row.arrangedSubviews {
                    if imageIndex >= sessionNumber {
                        return
                    }
                    
                    if let imageView = imageView as? UIImageView {
                        // Меняем изображение на "не готовое" из массива notreadyImages
                        imageView.image = UIImage(named: notreadyImages[currentreadyIndex])
                    }
                    imageIndex += 1
                }
            }
        }
    }
    // Очистка панели готовности
    func clearReadinessPanel() {
        // Удаляем все существующие подвиды из readinessStackView
        readinessStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Устанавливаем минимальную высоту панели
        readinessPanel.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                readinessPanel.removeConstraint(constraint)
            }
        }
        
        let newHeightConstraint = readinessPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        newHeightConstraint.isActive = true
        
        // Удаляем все старые верхние ограничения
        readinessPanel.superview?.constraints.forEach { constraint in
            if constraint.firstAttribute == .top && constraint.firstItem as? UIView == readinessPanel {
                readinessPanel.superview?.removeConstraint(constraint)
            }
        }
        
        let newTopConstraint = readinessPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: 670)
        newTopConstraint.isActive = true
        
        // Принудительно обновляем расположение панели с анимацией
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    // Установка начального состояния таймера
    func setupInitialState() {
        startButton.setTitle("Старт", for: .normal)
        startButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        stopButton.setTitle("Стоп", for: .normal)
        stopButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        timeLabel.text = "00:00"
    }
    
    // Установка выбранной задачи
    func setSelectedTask(task: TaskModel) {
        selectedTask = task
    }
}
