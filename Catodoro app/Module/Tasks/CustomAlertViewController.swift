import UIKit
// Протокол для делегата CustomAlertViewController
protocol CustomAlertViewControllerDelegate: AnyObject {
    func customAlertViewController(_ controller: CustomAlertViewController, didAddTask task: TaskModel)
    func customAlertViewController(_ controller: CustomAlertViewController, didDeleteTask task: TaskModel)
}
// Класс CustomAlertViewController, наследуемый от UIViewController и принимающий протоколы UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate
class CustomAlertViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    // Ссылка на родительский контроллер TasksViewController
    var tasksViewController: TasksViewController?
    // Слабая ссылка на делегат CustomAlertViewControllerDelegate
    weak var delegate: CustomAlertViewControllerDelegate?
    var taskToEdit: TaskModel?
    // Контекст CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    // Текстовое поле для заголовка задачи
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: "AnonymousPro-Regular", size: 24)
        textField.textColor = .black
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.placeholder = "Новая задача"
        return textField
    }()
    // Текстовое поле для описания задачи
    private let subtitleTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        textField.textColor = .black
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.placeholder = "С ней я обязательно справлюсь"
        return textField
    }()
    // Стековое представление для кнопок
    private var buttonStackView: UIStackView!
    // Лэйбл для уведомлений
    private let notifLabel = UILabel()
    // Контейнерное представление для элементов интерфейса
    private let containerView = UIView()
    // Кнопка удаления задачи
    private let deleteButton = UIButton(type: .system)
    // Кнопка сохранения задачи
    private let saveButton = UIButton(type: .system)
    // Кнопка выбора количества сессий
    private let sessionNumberButton = UIButton(type: .system)
    // Кнопка выбора длительности сессии
    private let sessionDurationButton = UIButton(type: .system)
    // Кнопка выбора длительности короткого отдыха
    private let shortRestDurationButton = UIButton(type: .system)
    // Кнопка выбора длительности длинного отдыха
    private let longRestDurationButton = UIButton(type: .system)
    // Кнопка выбора времени запуска длинного отдыха
    private let longRestTimeButton = UIButton(type: .system)
    // Кнопка для отметки готовности задачи
    @objc private  let readytaskButton = UIButton(type: .system)
    // Кнопка для выбора даты
    private let datePickerButton = UIButton(type: .system)
    // Переключатель для включения/выключения уведомлений
    private let notifySwitch = UISwitch()
    // Представление для UIPickerView
    private var pickerView = UIPickerView()
    // Заголовок для UIPickerView
    var pickerLabel = UILabel()
    // выбранная кнопка
    private var selectedButton: UIButton?
    // дата задачи
    private var taskDate = Date()
    let bannerLabel = UILabel()
    private var selectedValue: String?
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        
        return picker
    }()
    // Кнопка "Готово"
    private var doneButton: UIButton!
    // Кнопка "Отмена"
    private var cancelButton: UIButton!
    // Текущее представление UIPickerView
    private var currentPickerView: UIView?
    override func viewDidLoad() {
        // Установка светлой темы пользовательского интерфейса
        overrideUserInterfaceStyle = .light
        super.viewDidLoad()
        // Настройка интерфейса
        setupView()
        // Настройка пикера даты
        setupDatePicker()
        // Установка делегатов для пикера и текстовых полей
        pickerView.delegate = self
        pickerView.dataSource = self
        setupTextFields()
        // Настройка действия тапа
        setupTapGesture()
        // Заполнение полей данными задачи для редактирования, если таковая имеется
        if let task = taskToEdit {
            fillFields(with: task)
        } else {
            resetFields()
        }
    }
    // Метод для установки заголовка кнопки удаления задачи
    func setDeleteButtonTitle(_ title: String) {
        deleteButton.setTitle(title, for: .normal)
    }
    // Метод для заполнения полей данными задачи
    internal func fillFields(with task: TaskModel) {
        titleTextField.text = task.title
        subtitleTextField.text = task.subtitle
        sessionNumber = Int(task.sessionNumber)
        sessionDuration = Int(task.sessionDuration)
        shortRestDuration = Int(task.shortRestDuration)
        longRestDuration = Int(task.longRestDuration)
        longRestTime = Int(task.longRestTime)
        readinessNumber = Int(task.readinessNumber)
        taskDate = task.taskDate ?? Date()  // Если taskDate nil, установить текущую дату
        notifySwitch.isOn = task.canNotify
        sessionNumberButton.setTitle("\(sessionNumber)\n🟣", for: .normal)
        sessionDurationButton.setTitle("\(sessionDuration)\nмин", for: .normal)
        shortRestDurationButton.setTitle("\(shortRestDuration)\nмин", for: .normal)
        longRestDurationButton.setTitle("\(longRestDuration)\nмин", for: .normal)
        longRestTimeButton.setTitle("\(longRestTime)\n🟣", for: .normal)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateString = dateFormatter.string(from: taskDate)
        datePickerButton.setTitle(dateString, for: .normal)
        if taskToEdit != nil {
            deleteButton.setTitle("Удалить", for: .normal)
        } else {
            deleteButton.setTitle("Отмена", for: .normal)
        }
    }
    // Метод для сброса полей в начальное состояние
    internal func resetFields() {
        taskToEdit = nil
        titleTextField.text = ""
        subtitleTextField.text = ""
        sessionNumber = 5
        sessionDuration = 25
        shortRestDuration = 5
        longRestDuration = 15
        longRestTime = 3
        notifySwitch.isOn = false
        datePickerButton.setTitle("Когда?⏰", for: .normal)
        setDeleteButtonTitle("Отмена")
        sessionNumberButton.setTitle("\(sessionNumber)\n🟣", for: .normal)
        sessionDurationButton.setTitle("\(sessionDuration)\nмин", for: .normal)
        shortRestDurationButton.setTitle("\(shortRestDuration)\nмин", for: .normal)
        longRestDurationButton.setTitle("\(longRestDuration)\nмин", for: .normal)
        longRestTimeButton.setTitle("\(longRestTime)\n🟣", for: .normal)
        taskDate = Date()
        datePicker.date = taskDate
    }
    // Метод для настройки внешнего вида и расположения элементов интерфейса
    private func setupView() {
        view.backgroundColor = UIColor.white.withAlphaComponent(0)
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 25
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.addSubview(titleTextField)
        containerView.addSubview(subtitleTextField)
        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 18)
        deleteButton.backgroundColor = .catodoroRed
        deleteButton.layer.borderColor = UIColor.black.cgColor
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.cornerRadius = 15
        deleteButton.setTitleColor(.black, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        containerView.addSubview(deleteButton)
        
        readytaskButton.setImage(UIImage(named: "mainbutton2")?.withRenderingMode(.alwaysOriginal), for: .normal)
        readytaskButton.addTarget(self, action: #selector(readytaskButtonTapped), for: .touchUpInside)
        
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 18)
        saveButton.backgroundColor = .catodoroMidGreen
        saveButton.layer.borderColor = UIColor.black.cgColor
        saveButton.layer.borderWidth = 1
        saveButton.layer.cornerRadius = 15
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        containerView.addSubview(saveButton)
        
        titleTextField.text = "Новая задача"
        subtitleTextField.text = "С ней я обязательно справлюсь!"
        
        let buttonsStackView = UIStackView()
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .center
        buttonsStackView.spacing = 5
        buttonsStackView.distribution = .fillEqually
        containerView.addSubview(buttonsStackView)
        
        sessionNumberButton.setTitle("\(sessionNumber)\n🟣 ", for: .normal)
        sessionNumberButton.setTitleColor(UIColor.black, for: .normal)
        sessionNumberButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        sessionNumberButton.titleLabel?.lineBreakMode = .byCharWrapping
        sessionNumberButton.titleLabel?.numberOfLines=2
        sessionNumberButton.titleLabel?.textAlignment = .center
        sessionNumberButton.addTarget(self, action: #selector(sessionNumberButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(sessionNumberButton)
        
        sessionDurationButton.setTitle("\(sessionDuration)\nмин", for: .normal)
        sessionDurationButton.setTitleColor(UIColor.black, for: .normal)
        sessionDurationButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        sessionDurationButton.titleLabel?.lineBreakMode = .byCharWrapping
        sessionDurationButton.titleLabel?.textAlignment = .center
        sessionDurationButton.titleLabel?.numberOfLines=2
        sessionDurationButton.addTarget(self, action: #selector(sessionDurationButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(sessionDurationButton)
        
        shortRestDurationButton.setTitle("\(shortRestDuration)\nмин", for: .normal)
        shortRestDurationButton.setTitleColor(UIColor.black, for: .normal)
        shortRestDurationButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        shortRestDurationButton.titleLabel?.lineBreakMode = .byCharWrapping
        shortRestDurationButton.titleLabel?.numberOfLines=2
        shortRestDurationButton.titleLabel?.textAlignment = .center
        shortRestDurationButton.addTarget(self, action: #selector(shortRestDurationButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(shortRestDurationButton)
        
        longRestDurationButton.setTitle("\(longRestDuration)\nмин", for: .normal)
        longRestDurationButton.setTitleColor(UIColor.black, for: .normal)
        longRestDurationButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        longRestDurationButton.titleLabel?.lineBreakMode = .byCharWrapping
        longRestDurationButton.titleLabel?.numberOfLines=2
        longRestDurationButton.titleLabel?.textAlignment = .center
        longRestDurationButton.addTarget(self, action: #selector(longRestDurationButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(longRestDurationButton)
        
        longRestTimeButton.setTitle("\(longRestTime)\n🟣", for: .normal)
        longRestTimeButton.setTitleColor(UIColor.black, for: .normal)
        longRestTimeButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        longRestTimeButton.titleLabel?.lineBreakMode = .byCharWrapping
        longRestTimeButton.titleLabel?.numberOfLines=2
        longRestTimeButton.titleLabel?.textAlignment = .center
        longRestTimeButton.addTarget(self, action: #selector(longRestTimeButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(longRestTimeButton) // добавили кнопку в стек
        
        let bottomStackView = UIStackView()
        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .center
        bottomStackView.spacing = 5// уменьшили расстояние между кнопками
        bottomStackView.distribution = .equalCentering
        containerView.addSubview(bottomStackView)
        
        bottomStackView.addArrangedSubview(notifLabel)
        notifLabel.text="Уведомления"
        notifLabel.textColor = .catodoroBlack
        notifLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        
        bottomStackView.addArrangedSubview(notifySwitch) //
        notifySwitch.layer.borderColor = UIColor.black.cgColor
        notifySwitch.layer.borderWidth = 1
        notifySwitch.layer.cornerRadius=15
        notifySwitch.onTintColor = .catodoroMidGreen
        notifySwitch.tintColor = .catodoroRed
        notifySwitch.backgroundColor = .catodoroRed
        notifySwitch.isOn = false
        
        containerView.addSubview(datePickerButton)
        datePickerButton.layer.borderColor = UIColor.black.cgColor
        datePickerButton.layer.cornerRadius = 15
        datePickerButton.layer.borderWidth = 1
        datePickerButton.backgroundColor = .catodoroLightPurple
        datePickerButton.setTitle("Когда?⏰", for: .normal)
        datePickerButton.setTitleColor(UIColor.black, for: .normal)
        datePickerButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        datePickerButton.addTarget(self, action: #selector(datePickerButtonTapped), for: .touchUpInside)
        
        datePicker.backgroundColor = .catodoroLightPurple
        datePicker.layer.cornerRadius=25
        datePicker.layer.borderColor = UIColor.black.cgColor
        datePicker.layer.borderWidth = 1
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        datePicker.isHidden = true
        view.addSubview(containerView)
        view.addSubview(readytaskButton)
        containerView.addSubview(datePicker)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        subtitleTextField.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        datePickerButton.translatesAutoresizingMaskIntoConstraints = false
        notifLabel.translatesAutoresizingMaskIntoConstraints = false
        notifySwitch.translatesAutoresizingMaskIntoConstraints = false
        readytaskButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -60),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 350),
            containerView.heightAnchor.constraint(equalToConstant: 340),
            
            titleTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            titleTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            titleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            subtitleTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 5),
            subtitleTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            subtitleTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20),
            subtitleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            buttonsStackView.topAnchor.constraint(equalTo: subtitleTextField.bottomAnchor, constant: 10),
            buttonsStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonsStackView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 40),
            
            bottomStackView.topAnchor.constraint(equalTo: datePickerButton.bottomAnchor, constant: 20),
            bottomStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bottomStackView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -145),
            bottomStackView.heightAnchor.constraint(equalToConstant: 40),
            
            datePickerButton.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 20),
            datePickerButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            datePickerButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -165),
            datePickerButton.heightAnchor.constraint(equalToConstant: 40),
            
            deleteButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            deleteButton.widthAnchor.constraint(equalToConstant: 100),
            deleteButton.heightAnchor.constraint(equalToConstant: 40),
            
            readytaskButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            readytaskButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 17),
            readytaskButton.widthAnchor.constraint(equalToConstant: 75),
            readytaskButton.heightAnchor.constraint(equalToConstant: 75),
            
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            
            datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            datePicker.widthAnchor.constraint(equalToConstant: 350)
            
        ])
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.isHidden = true
        pickerView.backgroundColor = .catodoroLightPurple
        pickerView.layer.cornerRadius=25
        pickerView.layer.borderColor = UIColor.catodoroBlack.cgColor
        pickerView.layer.borderWidth=1
        view.addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerLabel.textAlignment = .center
        pickerLabel.font = UIFont(name: "AnonymousPro-Bold", size: 20)
        pickerLabel.isHidden = true
        view.addSubview(pickerLabel)
        pickerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pickerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickerLabel.bottomAnchor.constraint(equalTo: pickerView.topAnchor, constant: -5),
            
            pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -70),
            pickerView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    // Установка текстовых полей
    private func setupTextFields() {
        titleTextField.delegate = self
        subtitleTextField.delegate = self
    }
    
    // Обработка нажатия на экран
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    // Настройка пикера даты
    private func setupDatePicker() {
        // Настройка UIDatePicker
        datePicker.backgroundColor = .catodoroLightPurple
        datePicker.layer.cornerRadius = 15
        datePicker.layer.borderColor = UIColor.black.cgColor
        datePicker.layer.borderWidth = 1
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        datePicker.isHidden = true
        datePicker.layer.masksToBounds = true
        
        // Создание кнопок
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Готово", for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 18)
        doneButton.setTitleColor(UIColor.black, for: .normal)
        doneButton.backgroundColor = .catodoroMidGreen
        doneButton.layer.cornerRadius = 15
        doneButton.layer.borderColor = UIColor.black.cgColor
        doneButton.layer.borderWidth = 1
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отмена", for: .normal)
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        cancelButton.titleLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 18)
        cancelButton.layer.cornerRadius = 15
        cancelButton.backgroundColor = .catodoroRed
        cancelButton.layer.borderColor = UIColor.black.cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Настройка UIStackView
        buttonStackView = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 95
        buttonStackView.isHidden = true
        
        // Добавление элементов на view
        view.addSubview(buttonStackView)
        view.addSubview(datePicker)
        
        // Настройка Auto Layout
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,constant: 30),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,constant: -30),
            buttonStackView.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 10),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            
            datePicker.leadingAnchor.constraint(equalTo: pickerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: pickerView.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor),
            datePicker.widthAnchor.constraint(equalTo: pickerView.widthAnchor)
        ])
    }
    
    // Обработка нажатия на кнопку "Сохранить"
    @objc private func saveButtonTapped() {
        let isEditing = taskToEdit != nil
        guard let dateText = datePickerButton.titleLabel?.text, dateText != "Когда?⏰" else { return }
        guard let title = titleTextField.text, !title.isEmpty else {
            print("Title is empty")
            return
        }
        guard longRestTime <= sessionNumber else {
            // Показываем уведомление об ошибке
            let alert = UIAlertController(title: "Ошибка", message: "Количество рабочих сессий перед длинным перерывом не может быть больше общего количества рабочих сессий", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        if !isEditing {
            let newTask = TaskModel(title: title,
                                    subtitle: subtitleTextField.text,
                                    taskReadiness: false,
                                    readinessNumber: Int32(readinessNumber),
                                    shortRestDuration: Int32(shortRestDuration),
                                    sessionNumber: Int32(sessionNumber),
                                    sessionDuration: Int32(sessionDuration),
                                    longRestDuration: Int32(longRestDuration),
                                    longRestTime: Int32(longRestTime),
                                    taskDate: taskDate,
                                    canNotify: notifySwitch.isOn,
                                    context: context)
            
            delegate?.customAlertViewController(self, didAddTask: newTask)
        } else {
            guard let task = taskToEdit else {
                print("Task to edit is nil")
                return
            }
            task.title = title
            task.subtitle = subtitleTextField.text ?? ""
            task.sessionNumber = Int32(sessionNumber)
            task.sessionDuration = Int32(sessionDuration)
            task.shortRestDuration = Int32(shortRestDuration)
            task.longRestDuration = Int32(longRestDuration)
            task.longRestTime = Int32(longRestTime)
            task.taskDate = taskDate
            task.canNotify = notifySwitch.isOn
            delegate?.customAlertViewController(self, didAddTask: task)
        }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        pickerLabel.isHidden = true
        dismiss(animated: true, completion: nil)
    }
    
    // Скрытие клавиатуры
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    // Обработка нажатия на кнопку "Готово" в пикере даты
    @objc private func doneButtonTapped() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateString = dateFormatter.string(from: datePicker.date)
        datePickerButton.setTitle(dateString, for: .normal)
        datePicker.isHidden = true
        buttonStackView.isHidden = true
    }
    // Обработка нажатия на кнопку "Отменить"
    @objc private func cancelButtonTapped() {
        datePicker.isHidden = true
        buttonStackView.isHidden = true
    }
    // Обработка нажатия на кнопку "Удалить"
    @objc private func deleteButtonTapped() {
        guard let taskToEdit = taskToEdit else {
            print("No task to edit")
            dismiss(animated: true, completion: nil)
            return
        }
        // Вызов метода делегата для удаления задачи
        delegate?.customAlertViewController(self, didDeleteTask: taskToEdit)
        // Закрытие контроллера представления
        dismiss(animated: true, completion: nil)
    }
    
    protocol TaskSelectionDelegate: AnyObject {
        func didSelectTask(_ task: TaskModel)
    }
    // Обработка нажатия на кнопку "Готово"
    @objc private func readytaskButtonTapped() {
        guard let taskToEdit = taskToEdit else {
            return
        }
        var soundManager: SoundManager!
        soundManager.playSound(fileName: "happysound", type: "mp3", isRepeated: true)
        // Изменяем свойство готовности задачи
        taskToEdit.taskReadiness = true
        // Сохраняем изменения в Core Data
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            try context.save()
        } catch {
            print("Failed to save task readiness: \(error)")
        }
        NotificationCenter.default.post(name: .tasksDidUpdate, object: nil)
        // Добавляем анимацию и overlay view
        let overlayView = UIView(frame: containerView.bounds)
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        overlayView.layer.cornerRadius = 25
        containerView.addSubview(overlayView)
        let gifImageView = UIImageView(frame: CGRect(x: overlayView.frame.midX - 55, y: overlayView.frame.midY - 50, width: 103, height: 183))
        // Загрузка GIF-изображения
        if let gifURL = Bundle.main.url(forResource: "cat-dance-funny", withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL) {
            gifImageView.image = UIImage.gifImageWithData(gifData)
        }
        overlayView.addSubview(gifImageView)
        // Добавить баннер
        bannerLabel.frame = CGRect(x: 0, y: overlayView.bounds.midY - 130, width: overlayView.bounds.width, height: 100)
        bannerLabel.text = "Готово!"
        bannerLabel.font = UIFont(name: "AnonymousPro-Regular", size: 40)
        bannerLabel.textAlignment = .center
        bannerLabel.textColor = .catodoroBlack
        overlayView.addSubview(bannerLabel)
        // Добавить жест распознавания нажатия на прозрачный слой
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay(_:)))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Обновить таблицу в контроллере статистики
        if let parentController = self.presentingViewController as? StatisticsViewController {
            parentController.updateTasksForSelectedDate()
        }
    }
    // Обработка нажатия на экран после нажатия на кнопку "Готово"
    @objc func dismissOverlay(_ sender: UITapGestureRecognizer) {
        if let overlayView = sender.view {
            var soundManager: SoundManager!
            soundManager.stopSound()
            overlayView.removeFromSuperview()
            dismiss(animated: true, completion: nil)
        }
    }
    // Обработка нажатия на кнопку выбора количества сессий
    @objc private func sessionNumberButtonTapped() {
        selectedButton = sessionNumberButton
        showPickerView(for: sessionNumberButton)
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
    }
    // Обработка нажатия на кнопку выбора длительности сессий
    @objc private func sessionDurationButtonTapped() {
        showPickerView(for: sessionDurationButton)
        selectedButton = sessionDurationButton
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
    }
    // Обработка нажатия на кнопку выбора длительности короткого отдыха
    @objc private func shortRestDurationButtonTapped() {
        showPickerView(for: shortRestDurationButton)
        selectedButton = shortRestDurationButton
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
    }
    // Обработка нажатия на кнопку выбора длительности длинного отдыха
    @objc private func longRestDurationButtonTapped() {
        showPickerView(for: longRestDurationButton)
        selectedButton = longRestDurationButton
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
    }
    // Обработка нажатия на кнопку выбора времени длинного отдыха
    @objc private func longRestTimeButtonTapped() {
        showPickerView(for: longRestTimeButton)
        selectedButton = longRestTimeButton
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
    }
    // Обработка нажатия на кнопку выбора даты
    @objc private func datePickerButtonTapped() {
        datePicker.isHidden.toggle()
        buttonStackView.isHidden.toggle()
        if !datePicker.isHidden {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            if let selectedDate = dateFormatter.date(from: datePickerButton.titleLabel?.text ?? "") {
                datePicker.setDate(selectedDate, animated: false)
            }
        }
    }
    // Обработка изменения значения даты
    @objc private func dateChanged(_ sender: UIDatePicker) {
        self.taskDate = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateString = dateFormatter.string(from: sender.date)
        datePickerButton.setTitle(dateString, for: .normal)
    }
}
//Расширение для реализации PickerViewDataSource и PickerViewDelegate
extension CustomAlertViewController {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
   
    func showPickerView(for button: UIButton) {
        selectedButton = button
        pickerView.reloadAllComponents()
        pickerView.isHidden = false
        pickerLabel.isHidden = false
        
        switch button {
        case sessionNumberButton:
            pickerLabel.text = "Количество сессий"
            
        case sessionDurationButton:
            pickerLabel.text = "Длительность сессии"
        case shortRestDurationButton:
            pickerLabel.text = "Длительность короткого отдыха"
        case longRestTimeButton:
            pickerLabel.text = "Количество сессий до длинного отдыха"
        case longRestDurationButton:
            pickerLabel.text = "Длительность длинного отдыха"
        default:
            pickerLabel.text = ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch selectedButton {
        case sessionNumberButton:
            return sessionNumberOptions.count
        case sessionDurationButton:
            return sessionDurationOptions.count
        case shortRestDurationButton:
            return shortRestDurationOptions.count
        case longRestTimeButton:
            return restNumberOptions.count
        case longRestDurationButton:
            return longRestDurationOptions.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch selectedButton {
        case sessionNumberButton:
            return "\(sessionNumberOptions[row])"
        case sessionDurationButton:
            return "\(sessionDurationOptions[row])"
        case shortRestDurationButton:
            return "\(shortRestDurationOptions[row])"
        case longRestTimeButton:
            return "\(restNumberOptions[row])"
        case longRestDurationButton:
            return "\(longRestDurationOptions[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.isHidden = true
        
        switch selectedButton {
        case sessionNumberButton:
            sessionNumber = sessionNumberOptions[row]
            sessionNumberButton.setTitle("\(sessionNumber)\n🟣", for: .normal)
            pickerLabel.isHidden = true
        case sessionDurationButton:
            sessionDuration = sessionDurationOptions[row]
            sessionDurationButton.setTitle("\(sessionDuration)\nмин", for: .normal)
            pickerLabel.isHidden = true
        case shortRestDurationButton:
            shortRestDuration = shortRestDurationOptions[row]
            shortRestDurationButton.setTitle("\(shortRestDuration)\nмин", for: .normal)
            pickerLabel.isHidden = true
        case longRestDurationButton:
            longRestDuration = longRestDurationOptions[row]
            longRestDurationButton.setTitle("\(longRestDuration)\nмин", for: .normal)
            pickerLabel.isHidden = true
        case longRestTimeButton:
            longRestTime = restNumberOptions[row]
            longRestTimeButton.setTitle("\(longRestTime)\n🟣", for: .normal)
            pickerLabel.isHidden = true
        default:
            break
        }
    }
}
