import UIKit
//главный контроллер
class MainViewController: UIViewController, TasksViewController.TaskSelectionDelegate {
    //массив задач
    var tasks: [TaskModel] = []
    //экземпляр класса TimerManager для вызова его функций
    var timerManager: TimerManager!
    //экземпляр класса SoundManager для вызова его функций
    let soundManager = SoundManager()
    //панель готовности задач
    var readinessPanel: UIView!
    //экземпляр контроллера настроек
    var settingsViewController: SettingsViewController
    //выбранная задача
    var selectedTask: TaskModel? = nil
    //экземпляр контроллера задач
    var tasksViewController: TasksViewController
    // Инициализатор с параметром tasksViewController
    init(tasksViewController: TasksViewController) {
        self.tasksViewController = tasksViewController
        self.settingsViewController = Catodoro_app.SettingsViewController()
        super.init(nibName: nil, bundle: nil)
    }
    // Помечаем этот инициализатор как недоступный
    @available(*, unavailable, message: "Use init(tasksViewController:) instead")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // Объявляем все остальные свойства и компоненты интерфейса
    var motivationLabel = UILabel()
    var readinessStackView: UIStackView!
    let bannerLabel = UILabel()
    let circlePauseLayer = CAShapeLayer()
    let startButton = UIButton(type: .system)
    var timeLabel = UILabel()
    private var customTabBarController: UITabBarController?
    let optionsButton = UIButton(type: .system)
    let stopButton = UIButton(type: .system)
    private var options = ["Вариант 1", "Вариант 2", "Вариант 3"]
    var isTimerStarted=false
    var isAnimationStarted=false
    var isResting = false
    var isSessionStarted = false
    var time: Int = 0
    private var currentreadyIndex: Int = 0
    let foreProgressLayer=CAShapeLayer()
    let animation=CABasicAnimation(keyPath: "strokeEnd")
    private let catImages: [String] = ["cat1", "cat2", "cat3", "cat4", "cat5"]
    private let readyImages: [String] = ["fishReady", "bugReady", "mushReady"]
    private let notreadyImages: [String] = ["fishNotReady", "bugNotReady", "mushNotReady"]
    private lazy var pauseImage: UIImageView = {
        var pauseImage=UIImageView()
        pauseImage.image=UIImage(named: "pause")
        pauseImage.contentMode = .scaleAspectFit
        pauseImage.translatesAutoresizingMaskIntoConstraints=false
        pauseImage.widthAnchor.constraint(equalToConstant: 110).isActive=true
        pauseImage.heightAnchor.constraint(equalToConstant: 110).isActive=true
        return pauseImage
    }()
    
    private var backgroundIndex: Int = 0
    private var catIndex: Int = 0
    private let colors: [UIColor] = [.catodoroPink, .catodoroLightYellow, .catodoroPurple, .catodoroLightPurple, .catodoroLightGreen]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Инициализация компонентов интерфейса
        setReadinessPanel()
        setCircle()
        setTimeLabel()
        setCatImage()
        setMotivationLabel()
        setupButtons()
        setupTabBar()
        // Инициализация TimerManager
        timerManager = TimerManager(
            view: view,
            readinessStackView: readinessStackView,
            catImage: catImage,
            readinessPanel: readinessPanel,
            currentreadyIndex: 0,
            timeLabel: timeLabel, isRestingInternal: isResting,
            isSessionStarted:isSessionStarted,isTimerStarted:isTimerStarted,
            motivationLabel: motivationLabel,
            bannerLabel: bannerLabel,
            startButton: startButton,
            optionsButton: optionsButton,
            stopButton: stopButton,
            pauseImage: pauseImage,
            circlePauseLayer: circlePauseLayer, soundManager: soundManager, time: time
        )
        //Загрузка задач
        tasksViewController.loadTasks()
        self.tasks = tasksViewController.tasks
        
        // Загрузка сохраненной выбранной задачи
        if let savedTask = loadSelectedTask() {
            optionsButton.setTitle(savedTask.title, for: .normal)
            handleSelectedTask(savedTask)
            timerManager.setSelectedTask(task: savedTask)
        } else {
            optionsButton.setTitle("Выберите задачу", for: .normal)
        }
        
        foreProgressLayer.fillColor = UIColor.clear.cgColor
        NotificationCenter.default.addObserver(self, selector: #selector(handleTasksUpdate(notification:)), name: .tasksDidUpdate, object: nil)
        // Установить состояние переключателей из UserDefaults
        isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled")
        isVibrationEnabled = UserDefaults.standard.bool(forKey: "isVibrationEnabled")
        settingsViewController.soundSwitch.isOn = isSoundEnabled
        settingsViewController.vibrationSwitch.isOn = isVibrationEnabled
        
        // // Установить цвет фона  из UserDefaults
        if let savedColor = UserDefaults.standard.colorForKey(key: "backgroundColor") {
            view.backgroundColor = savedColor
            BackgroundColorManager.shared.setColor(savedColor)
            if let index = colors.firstIndex(of: savedColor) {
                backgroundIndex = index
            }
        } else {
            view.backgroundColor = BackgroundColorManager.shared.currentColor
        }
        // Установить иззображения котика из UserDefaults
        if let savedCatIndex = UserDefaults.standard.object(forKey: "currentCatIndex") as? Int {
            catIndex = savedCatIndex
            updateCatImage()
        }
        // Установить состояние изображения готовности из UserDefaults
        if let savedReadyIndex = UserDefaults.standard.object(forKey: "currentreadyIndex") as? Int {
            currentreadyIndex = savedReadyIndex
        } else {
            currentreadyIndex = 0
        }
        // Регистрация наблюдателей для изменения цвета фона и обновления изображений
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeBackgroundColor(_:)), name: .didChangeBackgroundColor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCatImage(notification:)), name: .updateCatImage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateReadinessImage(notification:)), name: .updateReadinessImage, object: nil)
    }
    //Установка изображения котика
    private func setCatImage() {
        let catContainerView = UIView()
        catContainerView.translatesAutoresizingMaskIntoConstraints = false
        catContainerView.backgroundColor = UIColor.clear
        catContainerView.layer.addSublayer(foreProgressLayer)
        catContainerView.addSubview(catImage)
        catImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            catImage.topAnchor.constraint(equalTo: catContainerView.topAnchor),
            catImage.bottomAnchor.constraint(equalTo: catContainerView.bottomAnchor),
            catImage.leadingAnchor.constraint(equalTo: catContainerView.leadingAnchor),
            catImage.trailingAnchor.constraint(equalTo: catContainerView.trailingAnchor)
        ])
        
        // Добавляем контейнер на основное представление
        view.addSubview(catContainerView)
        NSLayoutConstraint.activate([
            catContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.midY-400),
            catContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            catContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            catContainerView.widthAnchor.constraint(equalToConstant: 320)
        ])
    }
    //Изображение котика
    private lazy var catImage: UIImageView = {
        let catImageView = UIImageView()
        catImageView.image = UIImage(named: "cat1")
        catImageView.contentMode = .scaleAspectFit
        catImageView.translatesAutoresizingMaskIntoConstraints = false
        catImageView.widthAnchor.constraint(equalToConstant: 320).isActive = true
        catImageView.heightAnchor.constraint(equalToConstant: 330).isActive = true
        return catImageView
    }()
    // Метод для обновления изображения кота
    @objc private func updateCatImage(notification: Notification) {
        if let userInfo = notification.userInfo, let catIndex = userInfo["catIndex"] as? Int {
            let currentCatImageName = catImages[catIndex]
            catImage.image = UIImage(named: currentCatImageName)
        }
    }
    // Метод для изменения цвета фона
    @objc private func didChangeBackgroundColor(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            view.backgroundColor = color
        }
    }
    // Метод deinit для удаления наблюдателей
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeBackgroundColor, object: nil)
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .tasksDidUpdate, object: nil)
    }
    //Установка таб бара
    private func setupTabBar() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.5) // Устанавливаем полупрозрачный фон
        view.addSubview(containerView)
        let firstButton = UIButton(type: .system)
        firstButton.setImage(UIImage(named: "mainbutton1")?.withRenderingMode(.alwaysOriginal), for: .normal)
        firstButton.addTarget(self, action: #selector(firstButtonTapped), for: .touchUpInside)
        let secondButton = UIButton(type: .system)
        secondButton.setImage(UIImage(named: "mainbutton2")?.withRenderingMode(.alwaysOriginal), for: .normal)
        secondButton.addTarget(self, action: #selector(secondButtonTapped), for: .touchUpInside)
        let thirdButton = UIButton(type: .system)
        thirdButton.setImage(UIImage(named: "mainbutton3")?.withRenderingMode(.alwaysOriginal), for: .normal)
        thirdButton.addTarget(self, action: #selector(thirdButtonTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 105)
        ])
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.addArrangedSubview(firstButton)
        stackView.addArrangedSubview(secondButton)
        stackView.addArrangedSubview(thirdButton)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        customTabBarController = tabBarController
    }
    
    // Установка таймера
    private func setTimeLabel(){
        timeLabel.frame = CGRect(x: view.frame.midX-95, y: 80, width: 190, height: 60)
        timeLabel.text="00:00"
        timeLabel.font=catodoroFontRegular?.withSize(64)
        timeLabel.textColor = .catodoroBlack
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)
    }
    
    // Установка мотивационного баннера
    private func setMotivationLabel(){
        motivationLabel.frame = CGRect(x: view.frame.midX-140, y: 755, width: 300, height: 30)
        motivationLabel.text="Приступим?"
        motivationLabel.font=catodoroFontRusRegular?.withSize(26)
        motivationLabel.textColor = .catodoroBlack
        motivationLabel.textAlignment = .center
        view.addSubview(motivationLabel)
    }
    // Установка круга для таймера
    private func setCircle(){
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: view.frame.midX, y: view.frame.midY-130), radius: CGFloat(170), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.white.cgColor
        circleLayer.opacity=0.5
        circleLayer.strokeColor = UIColor.clear.cgColor
        view.layer.addSublayer(circleLayer)
    }
    
    // Установка панели готовности
    private func setReadinessPanel() {
        readinessPanel = UIView()
        readinessPanel.translatesAutoresizingMaskIntoConstraints = false
        readinessPanel.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
        readinessPanel.layer.cornerRadius = 25
        readinessPanel.layer.borderWidth = 1
        readinessPanel.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        readinessStackView = UIStackView()
        readinessStackView.axis = .vertical
        readinessStackView.alignment = .fill
        readinessStackView.distribution = .fillEqually
        readinessStackView.spacing = 3
        readinessPanel.addSubview(readinessStackView)
        readinessStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            readinessStackView.leadingAnchor.constraint(equalTo: readinessPanel.leadingAnchor, constant: 3),
            readinessStackView.trailingAnchor.constraint(equalTo: readinessPanel.trailingAnchor, constant: -3),
            readinessStackView.topAnchor.constraint(equalTo: readinessPanel.topAnchor, constant: 3),
            readinessStackView.bottomAnchor.constraint(equalTo: readinessPanel.bottomAnchor, constant: -3)
        ])
        
        view.addSubview(readinessPanel)
        NSLayoutConstraint.activate([
            readinessPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            readinessPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: 670),
            readinessPanel.widthAnchor.constraint(equalToConstant: 300),
            readinessPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60) // Минимальная высота
        ])
    }
    
    // Установка кнопок
    private func setupButtons() {
        startButton.setTitle("Старт", for: .normal)
        startButton.titleLabel?.font = UIFont(name: "AnonymousPro-Bold", size: 18)
        startButton.setTitleColor(.catodoroBlack, for: .normal)
        startButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        startButton.layer.cornerRadius = 19
        startButton.layer.borderWidth = 1
        startButton.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        stopButton.setTitle("Отменить", for: .normal)
        stopButton.titleLabel?.font = UIFont(name: "AnonymousPro-Bold", size: 18)
        stopButton.setTitleColor(.catodoroBlack, for: .normal)
        stopButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        stopButton.layer.cornerRadius = 19
        stopButton.layer.borderWidth = 1
        stopButton.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        optionsButton.setTitle("Задача", for: .normal)
        optionsButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        optionsButton.titleLabel?.textAlignment = .center
        optionsButton.setTitleColor(.black, for: .normal)
        optionsButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        optionsButton.layer.cornerRadius = 25
        optionsButton.layer.borderWidth = 1
        optionsButton.layer.borderColor = UIColor.black.cgColor
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        view.addSubview(optionsButton)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        // Устанавливаем констрейнты для кнопок
        NSLayoutConstraint.activate([
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70),
            startButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -30),
            startButton.widthAnchor.constraint(equalToConstant: 90),
            startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -255),
            startButton.heightAnchor.constraint(equalToConstant: 45),
            stopButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 30),
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -70),
            stopButton.widthAnchor.constraint(equalToConstant: 90),
            stopButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -255),
            stopButton.heightAnchor.constraint(equalToConstant: 45),
            optionsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            optionsButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -320),
            optionsButton.widthAnchor.constraint(equalToConstant: 300),
            optionsButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    // Обработка выбора задач
    private func handleSelectedTask(_ task: TaskModel) {
        self.selectedTask = task
        timerManager.setSelectedTask(task: task)
        timerManager.stopTimer()
        timerManager.resetTimer()
        timeLabel.text = "\(task.sessionDuration):00"
        timerManager.updateReadinessPanel(sessionNumber: Int(task.sessionNumber))
        for i in 0...task.readinessNumber {
            timerManager.updateReadiness(imageIndex: Int(i) - 1)
        }
        timerManager.updateTaskReadiness(task: task) // Обновляем Core Data
    }
    
    
    // Метод для получения уведомления о обновлении задач
    @objc func handleTasksUpdate(notification: Notification) {
        if let updatedTasks = notification.object as? [TaskModel] {
            self.tasks = updatedTasks
            // Проверяем, была ли выбранная задача удалена
            if let selectedTask = selectedTask, !tasks.contains(selectedTask) {
                self.selectedTask = nil
                self.optionsButton.setTitle("Выбрать задачу", for: .normal)
                timeLabel.text = "00:00"
            }
            
        }
    }
    // Обновление изображений на панели готовности
    @objc private func updateReadinessImage(notification: Notification) {
        if let userInfo = notification.userInfo, let currentreadyIndex = userInfo["currentreadyIndex"] as? Int {
            self.currentreadyIndex = currentreadyIndex
            timerManager.updateReadinessPanel(sessionNumber: sessionNumber)
        }
    }
    
    // Обновление изображения кота
    private func updateCatImage() {
        let currentCatImageName = catImages[catIndex]
        catImage.image = UIImage(named: currentCatImageName)
    }
    
    // Обновление изображения готовности
    private func updateReadinessImage() {
        let currentReadyImage = readyImages[currentreadyIndex]
        _ = notreadyImages[currentreadyIndex]
        catImage.image = UIImage(named: currentReadyImage)
        catImage.image = UIImage(named: currentReadyImage)
    }
    
    // Метод делегата для выбора задачи из контроллера задач
    func didSelectTask(_ task: TaskModel) {
        optionsButton.setTitle(task.title, for: .normal)
        handleSelectedTask(task)
        saveSelectedTask(task)
    }
    
    // Метод для сохранения выбранной задачи в UserDefaults
    func saveSelectedTask(_ task: TaskModel) {
        let defaults = UserDefaults.standard
        defaults.set(task.title, forKey: "selectedTaskTitle")
    }
    // Метод для загрузки выбранной задачи из UserDefaults
    func loadSelectedTask() -> TaskModel? {
        let defaults = UserDefaults.standard
        if let taskTitle = defaults.string(forKey: "selectedTaskTitle") {
            return tasks.first { $0.title == taskTitle }
        }
        return nil
    }
    // Жизненный цикл ViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedTask = loadSelectedTask() {
            optionsButton.setTitle(selectedTask.title, for: .normal)
            self.selectedTask = selectedTask 
            timerManager.setSelectedTask(task: selectedTask)
            handleSelectedTask(selectedTask)
        }
    }
    
    // Скрытие экрана  готовности
    @objc private func dismissOverlay(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
        bannerLabel.removeFromSuperview()
        soundManager.stopSound()
    }
    
    //Обработка нажатия на кнопку выбора задачи
    @objc private func optionsButtonTapped() {
        // Загружаем список задач
        tasksViewController.loadTasks()
        self.tasks = tasksViewController.tasks
        // Фильтруем задачи, чтобы исключить задачи с taskReadiness=true
        let activeTasks = tasks.filter { !$0.taskReadiness }
        // Создаем всплывающее окно с текущим списком задач
        let alert = UIAlertController(title: "Мои задачи", message: nil, preferredStyle: .actionSheet)
        let titleFont = UIFont(name: "AnonymousPro-Regular", size: 24.0) ?? UIFont.systemFont(ofSize: 17.0)
        let titleColor = UIColor.black
        let titleAttributedString = NSAttributedString(string: "Мои задачи", attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: titleColor])
        alert.setValue(titleAttributedString, forKey: "attributedTitle")
        // Добавляем действия для каждой задачи
        for task in activeTasks {
            let action = UIAlertAction(title: task.title, style: .default) { [weak self] _ in
                self?.optionsButton.setTitle(task.title, for: .normal)
                self?.handleSelectedTask(task)
            }
            alert.addAction(action)
        }
        // Добавляем действие для очистки списка задач
        let clearAction = UIAlertAction(title: "Очистить", style: .default) { [weak self] _ in
            guard let self = self, let timerManager = self.timerManager else { return }
            self.optionsButton.setTitle("Выберите задачу", for: .normal)
            timerManager.clearReadinessPanel()
        }
        alert.addAction(clearAction)
        let cancelAction = UIAlertAction(title: "Назад", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    protocol TaskSelectionDelegate: AnyObject {
        func didSelectTask(_ task: TaskModel)
    }
    
    // Дополнительный метод для обработки очистки выбранной задачи
    private func clearSelectedTask() {
        timerManager.clearReadinessPanel()
        selectedTask = nil
        timerManager.stopTimer()
        timerManager.resetTimer()
        timerManager.clearImage()
        
    }
    //Обработка нажатия на кнопку настроек
    @objc func firstButtonTapped() {
        settingsViewController.restorationIdentifier = "settingsViewController"
        settingsViewController.modalPresentationStyle = .fullScreen
        settingsViewController.modalTransitionStyle = .crossDissolve
        present(settingsViewController, animated: true, completion: nil)
    }
    //Обработка нажатия на кнопку готовности задачи
    @objc func secondButtonTapped() {
        guard selectedTask != nil else { return }
        AnimationManager.stopAnimation()
        if let selectedTaskTitle = optionsButton.title(for: .normal) {
            if let index = tasks.firstIndex(where: { $0.title == selectedTaskTitle }) {
                let selectedTask = tasks[index]
                selectedTask.taskReadiness = true
            }
        }
        optionsButton.setTitle("Выберите задачу", for: .normal)
        timerManager.showCompletionOverlay()
        timerManager.stopTimer()
        timerManager.resetTimer()
        timerManager.clearReadinessPanel()
        timerManager.setupInitialState()
    }
    //Обработка нажатия на кнопку списка задач
    @objc func thirdButtonTapped() {
        let tasksVC = TasksViewController()
        tasksVC.delegate = self
        tasksVC.tasks = tasks // Передача задач в контроллер задач
        tasksVC.modalPresentationStyle = .fullScreen
        tasksVC.modalTransitionStyle = .crossDissolve
        present(tasksVC, animated: true, completion: nil)
    }
    
    //Обработка нажатия на кнопку "Старт"
    @objc private func startButtonTapped() {
        guard selectedTask != nil else {
            print("No task selected")
            return
        }
        
        stopButton.isEnabled = true
        stopButton.alpha = 1.0
        
        if !timerManager.isSessionStarted {
            timerManager.startWorkSession()
            isTimerStarted = true // Update timer state
        } else {
            if timerManager.isResting {
                timerManager.startWorkSession()
            } else {
                if isTimerStarted {
                    timerManager.pauseTimer()
                    isTimerStarted = false // Update timer state
                } else {
                    timerManager.resumeTimer()
                    isTimerStarted = true // Update timer state
                }
            }
        }
    }
    //Обработка нажатия на кнопку "Стоп"
    @objc private func stopButtonTapped() {
        timerManager.stopTimer()
        timerManager.resetTimer()
        motivationLabel.text="Приступим?"
    }
}




