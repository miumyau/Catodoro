import UIKit
// Основной класс TaskTableView, который наследуется от UIView и реализует протоколы UITableViewDataSource и UITableViewDelegate
class TaskTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    // Переменная, определяющая, находится ли таблица в контроллере статистики
    var isInStatisticsViewController: Bool = false
    // Обработчик выбора задачи, вызываемый при выборе строки в таблице
    var taskSelectionHandler: ((TaskModel) -> Void)?
    // Массив задач, который обновляет таблицу при изменении
    var tasks: [TaskModel] = [] {
        didSet {
            print("Обновленные задачи в TaskTableView: \(tasks)")
            tableView.reloadData()
        }
    }
    // Основная таблица
    private let tableView = UITableView()
    
    // Массив отфильтрованных задач (только задачи, которые не завершены)
    private var filteredTasks: [TaskModel] {
        return tasks.filter { !$0.taskReadiness }
    }
    // Инициализатор для инициализации из кода
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTableView()
    }
    // Инициализатор для инициализации из storyboard или xib
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // Внутренний класс для кастомного accessory view с изображением и количеством сессий
    private class TaskAccessoryView: UIView {
        private let imageView: UIImageView
        private let label: UILabel
        // Инициализатор для создания кастомного accessory view
        init(image: UIImage?, readinessNumber: Int, sessionNumber: Int, isTaskReady: Bool) {
            imageView = UIImageView(image: image)
            label = UILabel()
            super.init(frame: .zero)
            setupView(readinessNumber: readinessNumber, sessionNumber: sessionNumber, isTaskReady: isTaskReady)
        }
        // Инициализатор для инициализации из storyboard или xib
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        // Настройка представления
        private func setupView(readinessNumber: Int, sessionNumber: Int, isTaskReady: Bool) {
            // Настройка imageView
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            // Настройка метки, если задача не готова
            if !isTaskReady {
                label.text = "\(readinessNumber)/\(sessionNumber)"
                label.font = UIFont(name: "AnonymousPro-Regular", size: 14)
                label.textColor = .black
                label.translatesAutoresizingMaskIntoConstraints = false
                label.textAlignment = .center
                addSubview(label)
                // Констрейнты для метки
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
                ])
            }
            // Констрейнты для imageView
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 40),
                imageView.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
    }
    // Настройка таблицы
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
        addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    // MARK: - TableView DataSource
    
    // Метод для указания количества строк в секции (в данном случае всегда одна строка на секцию)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1  // В каждой секции одна строка
    }
    
    // Метод для указания количества секций в таблице
    func numberOfSections(in tableView: UITableView) -> Int {
        if isInStatisticsViewController {
            return tasks.count // Отображаем все задачи
        } else {
            return filteredTasks.count // Отображаем только фильтрованные задачи
        }
    }
    
    // Метод для настройки ячейки таблицы
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        var task: TaskModel
        
        if isInStatisticsViewController {
            task = tasks[indexPath.section] // Используем все задачи
        } else {
            task = filteredTasks[indexPath.section] // Используем только фильтрованные задачи
        }
        // Установка текста заголовка задачи
        cell.textLabel?.text = task.title
        cell.textLabel?.textAlignment = .center
        // Определяем изображение в зависимости от готовности задачи
        let imageName = task.taskReadiness ? "mainbutton2" : "loading" // Предполагаемое изображение для готовности
        let image = UIImage(named: imageName)
        // Создаем кастомный accessory view с изображением и количеством сессий
        let accessoryView = TaskAccessoryView(image: image, readinessNumber: Int(task.readinessNumber), sessionNumber: Int(task.sessionNumber), isTaskReady: task.taskReadiness)
        // Устанавливаем размер accessoryView
        accessoryView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        // Устанавливаем новый кастомный accessory view
        cell.accessoryView = accessoryView
        return cell
    }
    
    // MARK: - TableView Delegate
    
    // Метод для обработки выбора строки в таблице
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < filteredTasks.count else {
            print("Индекс вне диапазона при выборе ячейки.")
            return
        }
        let selectedTask = filteredTasks[indexPath.section]
        if !isInStatisticsViewController {
            // Обработать выбор задачи только если не в контроллере статистики
            taskSelectionHandler?(selectedTask)
        }
    }
    
    // Метод для указания высоты строки
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75  // Устанавливаем высоту ячейки
    }
    
    // Метод для указания высоты заголовка секции
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    // Метод для указания вида заголовка секции
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
}

// Класс для ячейки таблицы TaskTableViewCell, наследуемый от UITableViewCell
class TaskTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    // Инициализатор для инициализации из storyboard или xib
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Метод для настройки UI элементов ячейки
    private func setupUI() {
        self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        self.layer.cornerRadius = 25
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        let selectedView = UIView()
        selectedView.backgroundColor = .clear
        self.selectedBackgroundView = selectedView
        
        // Установка выравнивания текста по центру
        self.textLabel?.textAlignment = .center
        // Включение автопереноса текста
        self.textLabel?.font = UIFont(name: "AnonymousPro-Regular", size: 22)
        self.textLabel?.textColor = .catodoroBlack
        self.textLabel?.numberOfLines = 0
        self.textLabel?.lineBreakMode = .byWordWrapping
    }
}
