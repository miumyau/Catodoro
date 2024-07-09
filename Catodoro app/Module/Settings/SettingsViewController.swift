import UIKit
// Контроллер для настройки приложения
class SettingsViewController: UIViewController {
    // Создаем кнопки и переключатели
    let backButton = UIButton(type: .custom)
    let rateButton = UIButton(type: .custom)
    let backgroundButton = UIButton(type: .custom)
    let catButton = UIButton(type: .custom)
    let readinessButton = UIButton(type: .custom)
    let soundSwitch = UISwitch()
    let vibrationSwitch = UISwitch()
    var secondView = UIView()
    // Определяем массивы цветов, текстов и изображений
    private let colors: [UIColor] = [.catodoroPink, .catodoroLightYellow, .catodoroPurple, .catodoroLightPurple, .catodoroLightGreen]
    private let catColors: [UIColor] = [.cat1, .cat2, .cat3, .cat4, .cat5]
    private let texts: [String] = ["Зефирка", "Песок", "Сирень", "Лаванда", "Мята"]
    private let catNames: [String] = ["Персик", "Мурзик", "Китти", "Бархат", "Клубничка"]
    private let catImages: [String] = ["cat1", "cat2", "cat3", "cat4", "cat5"]
    private let readyImages: [String] = ["fishReady", "bugReady", "mushReady"]
    private let notreadyImages: [String] = ["fishNotReady", "bugNotReady", "mushNotReady"]
    // Индексы для отслеживания текущих значений
    private var backgroundIndex: Int = 0
    private var catIndex: Int = 0
    private var currentreadyIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Загрузка сохраненных настроек
        if let savedColor = UserDefaults.standard.colorForKey(key: "backgroundColor") {
            view.backgroundColor = savedColor
            BackgroundColorManager.shared.setColor(savedColor)
            if let index = colors.firstIndex(of: savedColor) {
                backgroundIndex = index
            }
        } else {
            view.backgroundColor = BackgroundColorManager.shared.currentColor
        }
        
        if let savedBackgroundIndex = UserDefaults.standard.object(forKey: "backgroundIndex") as? Int {
            backgroundIndex = savedBackgroundIndex
            updateBackgroundColor()
        }
        // Загрузка сохраненного котика
        if let savedCatIndex = UserDefaults.standard.object(forKey: "currentCatIndex") as? Int {
            catIndex = savedCatIndex
            updateCat()
        }
        if let savedReadyIndex = UserDefaults.standard.object(forKey: "currentreadyIndex") as? Int {
            currentreadyIndex = savedReadyIndex
        } else {
            currentreadyIndex = 0 // Или другой индекс по умолчанию
        }
        // Загрузка настроек звука и вибрации
        isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled")
        isVibrationEnabled = UserDefaults.standard.bool(forKey: "isVibrationEnabled")
        // Настройка второго представления
        secondView.frame = CGRect(x: 0, y: 0, width: 350, height: 370)
        secondView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.59).cgColor
        secondView.layer.cornerRadius = 25
        let parent = self.view!
        parent.addSubview(secondView)
        secondView.translatesAutoresizingMaskIntoConstraints = false
        secondView.heightAnchor.constraint(equalToConstant: 370).isActive = true
        secondView.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -30).isActive = true
        secondView.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 30).isActive = true
        secondView.topAnchor.constraint(equalTo: parent.topAnchor, constant: 100).isActive = true
        setupUI()
        setupActions()
        setBackButton()
        setSphynxImage()
        // Подписка на уведомление об изменении цвета фона
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeBackgroundColor(_:)), name: .didChangeBackgroundColor, object: nil)
    }
    // Сохраняем цвет фона в UserDefaults
    private func updateBackgroundColor() {
        let currentColor = colors[backgroundIndex]
        let currentText = texts[backgroundIndex]
        backgroundButton.setTitle(currentText, for: .normal)
        backgroundButton.backgroundColor = currentColor
        view.backgroundColor = currentColor
    }
    // Обновление информации о текущем котике
    private func updateCat() {
        let currentName = catNames[catIndex]
        let currentCatColor = catColors[catIndex]
        _ = catImages[catIndex]
        catButton.setTitle(currentName, for: .normal)
        catButton.backgroundColor = currentCatColor
        UserDefaults.standard.set(currentName, forKey: "currentCatName")
        UserDefaults.standard.setColor(color: currentCatColor, forKey: "currentCatColor")
    }
    // MARK: - Настройка UI
    private func setupUI() {
        let labels = ["Фон", "Котик", "Готовность", "Звук", "Вибрация", "Уведомления"]
        _ = [backgroundButton, catButton, readinessButton]
        let currentColor = colors[backgroundIndex]
        let currentText = texts[backgroundIndex]
        let currentName = catNames[catIndex]
        let currentCatColor = catColors[catIndex]
        let currentReadyImage = readyImages[currentreadyIndex]
        _ = notreadyImages[currentreadyIndex]
        let backgroundLabel = UILabel()
        backgroundLabel.text = labels[0]
        backgroundLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        view.addSubview(backgroundLabel)
        backgroundLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundLabel.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: 20).isActive = true
        backgroundLabel.topAnchor.constraint(equalTo: secondView.topAnchor, constant: 50).isActive = true
        backgroundButton.setTitle( currentText, for: .normal)
        backgroundButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        backgroundButton.setTitle(currentText, for: .normal)
        backgroundButton.backgroundColor = currentColor
        // Меняем цвет фона текущего контроллера
        view.backgroundColor = currentColor
        backgroundButton.layer.borderColor = UIColor.black.cgColor
        backgroundButton.layer.borderWidth = 1
        backgroundButton.layer.cornerRadius = 15
        backgroundButton.clipsToBounds = true
        view.addSubview(backgroundButton)
        backgroundButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundButton.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -20).isActive = true
        backgroundButton.centerYAnchor.constraint(equalTo: backgroundLabel.centerYAnchor).isActive = true
        backgroundButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        backgroundButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let catLabel = UILabel()
        catLabel.text = labels[1]
        catLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        view.addSubview(catLabel)
        catLabel.translatesAutoresizingMaskIntoConstraints = false
        catLabel.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: 20).isActive = true
        catLabel.topAnchor.constraint(equalTo: backgroundLabel.bottomAnchor, constant: 40).isActive = true
        catButton.setTitle(currentName, for: .normal)
        catButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        catButton.backgroundColor = currentCatColor
        catButton.layer.borderColor = UIColor.black.cgColor
        catButton.layer.borderWidth = 1
        catButton.layer.cornerRadius = 15
        catButton.clipsToBounds = true
        view.addSubview(catButton)
        catButton.translatesAutoresizingMaskIntoConstraints = false
        catButton.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -20).isActive = true
        catButton.centerYAnchor.constraint(equalTo: catLabel.centerYAnchor).isActive = true
        catButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        catButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let readinessLabel = UILabel()
        readinessLabel.text = labels[2]
        readinessLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        view.addSubview(readinessLabel)
        readinessLabel.translatesAutoresizingMaskIntoConstraints = false
        readinessLabel.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: 20).isActive = true
        readinessLabel.topAnchor.constraint(equalTo: catLabel.bottomAnchor, constant: 40).isActive = true
        readinessButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        readinessButton.backgroundColor = .catodoroSand
        readinessButton.setImage(UIImage(named: currentReadyImage)?.withRenderingMode(.automatic), for: .normal)
        readinessButton.imageView?.contentMode = .scaleAspectFit
        readinessButton.layer.borderColor = UIColor.black.cgColor
        readinessButton.layer.borderWidth = 1
        readinessButton.layer.cornerRadius = 15
        readinessButton.clipsToBounds = true
        view.addSubview(readinessButton)
        readinessButton.translatesAutoresizingMaskIntoConstraints = false
        readinessButton.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -20).isActive = true
        readinessButton.centerYAnchor.constraint(equalTo: readinessLabel.centerYAnchor).isActive = true
        readinessButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        readinessButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let soundLabel = UILabel()
        soundLabel.text = labels[3]
        soundLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        view.addSubview(soundLabel)
        soundLabel.translatesAutoresizingMaskIntoConstraints = false
        soundLabel.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: 20).isActive = true
        soundLabel.topAnchor.constraint(equalTo: readinessLabel.bottomAnchor, constant: 40).isActive = true
        soundSwitch.layer.borderColor = UIColor.black.cgColor
        soundSwitch.layer.borderWidth = 1
        soundSwitch.layer.cornerRadius = 15
        soundSwitch.onTintColor = .catodoroMidGreen
        soundSwitch.tintColor = .catodoroRed
        soundSwitch.backgroundColor = .catodoroRed
        soundSwitch.isOn = false
        view.addSubview(soundSwitch)
        soundSwitch.translatesAutoresizingMaskIntoConstraints = false
        soundSwitch.centerYAnchor.constraint(equalTo: soundLabel.centerYAnchor).isActive = true
        soundSwitch.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -50).isActive = true
        let vibrationLabel = UILabel()
        vibrationLabel.text = labels[4]
        vibrationLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        view.addSubview(vibrationLabel)
        vibrationLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrationLabel.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: 20).isActive = true
        vibrationLabel.topAnchor.constraint(equalTo: soundLabel.bottomAnchor, constant: 40).isActive = true
        vibrationSwitch.layer.borderColor = UIColor.black.cgColor
        vibrationSwitch.layer.borderWidth = 1
        vibrationSwitch.layer.cornerRadius = 15
        vibrationSwitch.onTintColor = .catodoroMidGreen
        vibrationSwitch.tintColor = .catodoroRed
        vibrationSwitch.backgroundColor = .catodoroRed
        vibrationSwitch.isOn = false
        view.addSubview(vibrationSwitch)
        vibrationSwitch.translatesAutoresizingMaskIntoConstraints = false
        vibrationSwitch.centerYAnchor.constraint(equalTo: vibrationLabel.centerYAnchor).isActive = true
        vibrationSwitch.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -50).isActive = true
        soundSwitch.isOn = isSoundEnabled
        vibrationSwitch.isOn = isVibrationEnabled
        rateButton.setTitle("Поставить оценку", for: .normal)
        rateButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 24)
        rateButton.backgroundColor = UIColor(named: "CatodoroGreen")
        rateButton.layer.cornerRadius = 25
        rateButton.layer.borderWidth = 2.5
        rateButton.layer.borderColor = UIColor.catodoroBlack.cgColor
        rateButton.clipsToBounds = true
        view.addSubview(rateButton)
        rateButton.translatesAutoresizingMaskIntoConstraints = false
        rateButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        rateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        rateButton.widthAnchor.constraint(equalToConstant: 310).isActive = true
        rateButton.heightAnchor.constraint(equalToConstant: 70).isActive = true
    }
    
    private func setBackButton() {
        backButton.setImage(UIImage(named: "backImage"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private lazy var sphynxImage: UIImageView = {
        var sphynxImage = UIImageView()
        sphynxImage.image = UIImage(named: "hoch")
        sphynxImage.contentMode = .scaleAspectFit
        sphynxImage.translatesAutoresizingMaskIntoConstraints = false
        return sphynxImage
    }()
    
    private func setSphynxImage() {
        view.addSubview(sphynxImage)
        NSLayoutConstraint.activate([
            sphynxImage.topAnchor.constraint(equalTo: secondView.bottomAnchor, constant: 80),
            sphynxImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sphynxImage.widthAnchor.constraint(equalToConstant: 145),
            sphynxImage.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    // MARK: - Действия кнопок
    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func rateButtonTapped() {
           if let url = URL(string: "https://github.com/miumyau") {
               if UIApplication.shared.canOpenURL(url) {
                   UIApplication.shared.open(url, options: [:], completionHandler: nil)
               }
           }
       }
    
    private func setupActions() {
        backgroundButton.addTarget(self, action: #selector(backgroundButtonTapped), for: .touchUpInside)
        catButton.addTarget(self, action: #selector(catButtonTapped), for: .touchUpInside)
        readinessButton.addTarget(self, action: #selector(readinessButtonTapped), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(soundSwitchToggled), for: .valueChanged)
        vibrationSwitch.addTarget(self, action: #selector(vibrationSwitchToggled), for: .valueChanged)
        rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
    }

    // Действие при нажатии на кнопку изменения котика
    @objc private func catButtonTapped() {
        // Смена котика
        catIndex = (catIndex + 1) % catNames.count
        let currentName = catNames[catIndex]
        let currentCatColor = catColors[catIndex]
        catButton.setTitle(currentName, for: .normal)
        catButton.backgroundColor = currentCatColor
        UserDefaults.standard.set(currentName, forKey: "currentCatName")
        UserDefaults.standard.setColor(color: currentCatColor, forKey: "currentCatColor")
        // Сохраняем текущий индекс котика
        UserDefaults.standard.set(catIndex, forKey: "currentCatIndex")
        // Отправляем уведомление с текущим индексом
        NotificationCenter.default.post(name: .updateCatImage, object: nil, userInfo: ["catIndex": catIndex])
    }
    // Действие при нажатии на кнопку изменения фона
    @objc private func backgroundButtonTapped() {
        // Вычисляем индекс следующего цвета
        backgroundIndex = (backgroundIndex + 1) % colors.count
        let currentColor = colors[backgroundIndex]
        let currentText = texts[backgroundIndex]
        // Меняем цвет и текст кнопки
        backgroundButton.setTitle(currentText, for: .normal)
        backgroundButton.backgroundColor = currentColor
        // Меняем цвет фона текущего контроллера
        view.backgroundColor = currentColor
        // Обновляем цвет фона в BackgroundColorManager
        BackgroundColorManager.shared.setColor(currentColor)
        // Сохраняем цвет в UserDefaults
        UserDefaults.standard.setColor(color: currentColor, forKey: "backgroundColor")
        UserDefaults.standard.set(backgroundIndex, forKey: "backgroundIndex")
    }
    
    @objc private func didChangeBackgroundColor(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            view.backgroundColor = color
        }
    }
    // Действие при нажатии на кнопку изменения изображения готовности
    @objc private func readinessButtonTapped() {
        currentreadyIndex = (currentreadyIndex + 1) % readyImages.count
        guard currentreadyIndex < readyImages.count else { return }
        let currentReadyImage = readyImages[currentreadyIndex]
        _ = notreadyImages[currentreadyIndex]
        // Меняем изображение кнопки
        readinessButton.setImage(UIImage(named: currentReadyImage)?.withRenderingMode(.automatic), for: .normal)
        readinessButton.imageView?.contentMode = .scaleAspectFit
        // Сохраняем текущий индекс в UserDefaults
        UserDefaults.standard.set(currentreadyIndex, forKey: "currentreadyIndex")
        // Отправляем уведомление с текущим индексом
        NotificationCenter.default.post(name: .updateReadinessImage, object: nil, userInfo: ["currentreadyIndex": currentreadyIndex])
    }
    // Действие при изменении состояния переключателя звука
    @objc private func soundSwitchToggled() {
        isSoundEnabled = soundSwitch.isOn
        UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
    }
    // Действие при изменении состояния переключателя вибрации
    
    @objc private func vibrationSwitchToggled() {
        isVibrationEnabled = vibrationSwitch.isOn
        UserDefaults.standard.set(isVibrationEnabled, forKey: "isVibrationEnabled")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeBackgroundColor, object: nil)
    }
}




