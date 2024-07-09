import UIKit
import FSCalendar
import CoreData
class StatisticsViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    // Цвета для фона представления
    private let colors: [UIColor] = [.catodoroPink, .catodoroLightYellow, .catodoroPurple, .catodoroLightPurple, .catodoroLightGreen]
    
    // Элементы интерфейса
    let calendar = FSCalendar() // Календарь
    private let taskTableView = TaskTableView() // Таблица задач
    private var currentIndex: Int = 0
    let backButton = UIButton(type: .custom) // Кнопка "Назад"
    let customHeaderLabel = UILabel() // Пользовательский заголовок
    var tasks: [TaskModel] = [] { // Массив задач
        didSet {
            updateTasksForSelectedDate() // Обновление задач для выбранной даты при изменении массива задач
        }
    }
    private var backgroundIndex: Int = 0
    private var selectedDate: Date? { // Выбранная дата
        didSet {
            updateTasksForSelectedDate() // Обновление задач для выбранной даты при изменении выбранной даты
            calendar.reloadData() // Обновление календаря
        }
    }
    
    // Метод, вызываемый при загрузке представления
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Подписка на уведомления
        NotificationCenter.default.addObserver(self, selector: #selector(updateTasksForSelectedDate), name: .tasksDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeBackgroundColor(_:)), name: .didChangeBackgroundColor, object: nil)
        
        // Настройка делегата и источника данных для календаря
        calendar.delegate = self
        calendar.dataSource = self
        
        // Установка цвета фона
        if let savedColor = UserDefaults.standard.colorForKey(key: "backgroundColor") {
            view.backgroundColor = savedColor
            BackgroundColorManager.shared.setColor(savedColor)
            if let index = colors.firstIndex(of: savedColor) {
                backgroundIndex = index
            }
        } else {
            view.backgroundColor = BackgroundColorManager.shared.currentColor
        }
        
        // Настройка элементов интерфейса
        setupCalendar()
        setupCustomHeaderLabel()
        setBackButton()
        setupTaskTableView()
        
        // Установка текущей даты по умолчанию
        loadTasks()
        selectedDate = Date()
        updateTasksForSelectedDate()
    }
    
    // Метод для загрузки задач из Core Data
    func loadTasks() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskModel> = TaskModel.fetchRequest()
        do {
            tasks = try context.fetch(fetchRequest)
            print("Загруженные задачи: \(tasks)")
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }
    
    // Метод для изменения фона при получении уведомления
    @objc private func didChangeBackgroundColor(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            view.backgroundColor = color
        }
    }
    
    // Метод для удаления наблюдателей при деинициализации
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeBackgroundColor, object: nil)
        NotificationCenter.default.removeObserver(self, name: .tasksDidUpdate, object: nil)
    }
    
    // Метод для настройки календаря
    private func setupCalendar() {
        calendar.delegate = self
        calendar.dataSource = self
        calendar.appearance.headerTitleFont = UIFont(name: "AnonymousPro-Regular", size: 20)
        calendar.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        calendar.appearance.weekdayFont = UIFont(name: "AnonymousPro-Regular", size: 16)
        calendar.appearance.titleFont = UIFont(name: "AnonymousPro-Regular", size: 16)
        calendar.layer.cornerRadius = 25
        calendar.clipsToBounds = true
        calendar.appearance.headerDateFormat = ""
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.appearance.headerTitleColor = .black
        calendar.layer.borderColor = UIColor.black.cgColor
        calendar.layer.borderWidth = 1.0
        calendar.calendarWeekdayView.weekdayLabels.forEach { label in
            label.textColor = .black
        }
        view.addSubview(calendar)
        calendar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendar.heightAnchor.constraint(equalToConstant: 300)
        ])
        updateCalendarHeader()
    }
    
    // Метод для настройки таблицы задач
    private func setupTaskTableView() {
        taskTableView.isInStatisticsViewController = true
        view.addSubview(taskTableView)
        taskTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            taskTableView.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 20),
            taskTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            taskTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            taskTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    // Метод для обновления задач для выбранной даты
    @objc func updateTasksForSelectedDate() {
        guard let selectedDate = selectedDate else {
            taskTableView.tasks = []
            return
        }
        let calendar = Calendar.current
        let filteredTasks = tasks.filter {
            guard let taskDate = $0.taskDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: selectedDate)
        }
            .sorted(by: { $0.taskDate! < $1.taskDate! })
        
        taskTableView.tasks = filteredTasks
        print("Фильтрованные задачи для выбранной даты \(selectedDate): \(filteredTasks)")
    }
    
    // Метод для настройки пользовательского заголовка
    private func setupCustomHeaderLabel() {
        customHeaderLabel.font = UIFont(name: "AnonymousPro-Regular", size: 20)
        customHeaderLabel.textColor = .black
        customHeaderLabel.textAlignment = .center
        view.addSubview(customHeaderLabel)
        customHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customHeaderLabel.topAnchor.constraint(equalTo: calendar.topAnchor, constant: 5),
            customHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customHeaderLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // Метод для настройки кнопки "Назад"
    private func setBackButton() {
        backButton.setImage(UIImage(named: "backImage"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // Метод для обработки нажатия на кнопку "Назад"
    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // Метод делегата FSCalendar для изменения текущей страницы календаря
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        updateCalendarHeader()
    }
    
    // Флаг для отслеживания, выбрал ли пользователь дату
    private var userDidSelectDate = false
    
    // Метод делегата FSCalendar для выбора даты
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if !userDidSelectDate {
            selectedDate = date
        }
        userDidSelectDate = true
    }
    
    // Метод делегата FSCalendar для снятия выделения с даты
    func calendar(_ calendar: FSCalendar, didDeselect date: Date) {
        if !userDidSelectDate {
            selectedDate = nil
        }
        userDidSelectDate = false
    }
    
    // Метод делегата FSCalendar для проверки возможности выбора даты
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        // Проверяем, была ли выбрана другая дата ранее
        if let selectedDate = selectedDate, Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            // Если выбрана та же дата, то снимаем выделение
            self.selectedDate = nil
            return false
        } else {
            // Если другая дата не была выбрана ранее, то выделяем новую дату
            self.selectedDate = date
            return true
        }
    }
    
    // Метод делегата FSCalendar для изменения цвета выделенной даты
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        if let selectedDate = selectedDate, Calendar.current.isDate(date, inSameDayAs: selectedDate) {
            return .catodoroGreen // Или любой другой цвет, который вы хотите использовать для выделенной даты
        }
        return nil // Убирает выделение с других дат
    }
    
    // Метод делегата FSCalendar для изменения цвета по умолчанию для даты
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        if Calendar.current.isDateInToday(date) {
            // Возвращаем цвет фона
            return view.backgroundColor // Используем цвет фона представления
        } else {
            // Возвращаем nil, чтобы использовать цвет по умолчанию для остальных дат
            return nil
        }
    }
    
    // Метод делегата FSCalendar для изменения цвета текста по умолчанию для даты
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if Calendar.current.isDateInToday(date) {
            // Возвращаем черный цвет для текста сегодняшней даты
            return UIColor.black
        } else {
            // Возвращаем nil, чтобы использовать цвет по умолчанию для остальных дат
            return nil
        }
    }
    
    // Метод для обновления заголовка календаря
    private func updateCalendarHeader() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        let formattedString = formatter.string(from: calendar.currentPage).capitalizingFirstLetter()
        customHeaderLabel.text = formattedString
    }
}
