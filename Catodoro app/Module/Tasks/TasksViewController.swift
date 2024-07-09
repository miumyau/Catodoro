import UIKit
import CoreData
// Основной класс TasksViewController, который наследуется от UIViewController и реализует протокол CustomAlertViewControllerDelegate
class TasksViewController: UIViewController, CustomAlertViewControllerDelegate {
    // Протокол для делегата выбора задачи
    protocol TaskSelectionDelegate: AnyObject {
        func didSelectTask(_ task: TaskModel)
    }
    // Свойства и переменные
    var tasksViewController: TasksViewController?
    var soundManager: SoundManager!
    private let taskTableView = TaskTableView() // Таблица задач
    weak var delegate: TaskSelectionDelegate? // Делегат для выбора задачи
    var tasks: [TaskModel] = [] { // Массив задач, обновляющий таблицу при изменении
        didSet {
            taskTableView.tasks = tasks
        }
    }
    var taskToEdit: TaskModel?
    var editViewController: CustomAlertViewController?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Контекст для Core Data
    
    // MARK: - Show Edit View Controller
    // Метод для показа контроллера редактирования
    func showEditViewController(with task: TaskModel?) {
        if editViewController == nil {
            editViewController = CustomAlertViewController()
            editViewController?.delegate = self
            loadTasks() // Загрузка задач
        }
        if let task = task {
            editViewController?.taskToEdit = task
            editViewController?.fillFields(with: task)
            loadTasks() // Загрузка задач
        } else {
            editViewController?.taskToEdit = nil
            editViewController?.resetFields()
            loadTasks() // Загрузка задач
        }
        if let presentedViewController = presentedViewController, presentedViewController == editViewController {
            return
        }
        if presentedViewController != editViewController {
            present(editViewController!, animated: true, completion: nil)
            loadTasks() // Загрузка задач
        }
    }
    
    // Метод для обработки добавления задачи из CustomAlertViewController
    func customAlertViewController(_ controller: CustomAlertViewController, didAddTask task: TaskModel) {
        if let existingTaskIndex = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[existingTaskIndex] = task
            loadTasks() // Загрузка задач
        } else {
            tasks.append(task)
            loadTasks() // Загрузка задач
        }
        saveTask() // Сохранение задачи
        tableView.reloadData()
    }
    
    // Метод для обработки удаления задачи из CustomAlertViewController
    func customAlertViewController(_ controller: CustomAlertViewController, didDeleteTask task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            context.delete(task)
            saveTask() // Сохранение задачи
            tableView.reloadData()
            loadTasks() // Загрузка задач
        }
        editViewController?.dismiss(animated: true) {
            self.editViewController?.resetFields()
        }
    }
    
    // Метод для загрузки задач из Core Data
    func loadTasks() {
        let fetchRequest: NSFetchRequest<TaskModel> = TaskModel.fetchRequest()
        NotificationCenter.default.post(name: .tasksDidUpdate, object: tasks)
        do {
            tasks = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }
    
    // Метод для сохранения задачи в Core Data
    func saveTask() {
        do {
            try context.save()
            print("Task successfully saved")
            loadTasks() // Загрузка задач после сохранения
            NotificationCenter.default.post(name: .tasksDidUpdate, object: tasks)
        } catch {
            print("Failed to save task: \(error)")
        }
    }
    
    // Свойства и UI элементы
    let backButton = UIButton(type: .custom)
    let statButton = UIButton(type: .custom)
    let newButton = UIButton(type: .custom)
    var mainLabel = UILabel()
    let buttonsStackView = UIStackView()
    var tableView = UITableView()
    private var currentIndex: Int = 0
    let cellSpacingHeight: CGFloat = 10 // Высота между секциями
    private let colors: [UIColor] = [.catodoroPink, .catodoroLightYellow, .catodoroPurple, .catodoroLightPurple, .catodoroLightGreen]
    
    // Метод, вызываемый при загрузке вида
    override func viewDidLoad() {
        overrideUserInterfaceStyle = .light
        super.viewDidLoad()
        setBackButton()
        setTable()
        setButtonsStack()
        setLabel()
        loadTasks() // Загрузка задач
        if let savedColor = UserDefaults.standard.colorForKey(key: "backgroundColor") {
            view.backgroundColor = savedColor
            BackgroundColorManager.shared.setColor(savedColor)
            if let index = colors.firstIndex(of: savedColor) {
                currentIndex = index
            }
        } else {
            view.backgroundColor = BackgroundColorManager.shared.currentColor
        }
        taskTableView.taskSelectionHandler = { [weak self] task in
            self?.showEditViewController(with: task)
        }
        // Подписываемся на уведомление о смене цвета
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeBackgroundColor(_:)), name: .didChangeBackgroundColor, object: nil)
    }
    
    // Метод, вызываемый при изменении фона
    @objc private func didChangeBackgroundColor(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            view.backgroundColor = color
        }
    }
    
    // Метод, вызываемый при деинициализации
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeBackgroundColor, object: nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    // Метод для удаления задачи
    func deleteTask(_ task: TaskModel) {
        context.delete(task)
        saveTask() // Сохранение задачи
        loadTasks() // Загрузка задач после удаления
    }
    
    // MARK: - UI Setup
    
    // Метод для настройки метки
    private func setLabel(){
        mainLabel.frame = CGRect(x: view.frame.midX-150, y: 60, width: 300, height: 60)
        mainLabel.text = "💖Мои задачи💖"
        mainLabel.font = UIFont(name: "AnonymousPro-Regular", size: 36)
        mainLabel.textColor = .catodoroBlack
        mainLabel.textAlignment = .center
        view.addSubview(mainLabel)
    }
    
    // Метод для настройки стека кнопок
    private func setButtonsStack() {
        buttonsStackView.axis = .vertical
        buttonsStackView.alignment = .center
        buttonsStackView.spacing = 20
        view.addSubview(buttonsStackView)
        
        newButton.setImage(UIImage(named: "newButton"), for: .normal)
        newButton.addTarget(self, action: #selector(newButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(newButton)
        
        statButton.setImage(UIImage(named: "statButton"), for: .normal)
        statButton.addTarget(self, action: #selector(statButtonTapped), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(statButton)
        
        newButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        newButton.heightAnchor.constraint(equalToConstant: 75).isActive = true
        statButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        statButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonsStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 310)
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
    
    // Метод для настройки таблицы
    private func setTable() {
        view.addSubview(taskTableView)
        taskTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            taskTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            taskTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            taskTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            taskTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -140)
        ])
    }
    
    // Метод для обработки нажатия на кнопку "Назад"
    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // Метод для обработки нажатия на кнопку "Новая задача"
    @objc func newButtonTapped() {
        showEditViewController(with: nil)
    }
    
    // Метод для добавления задачи
    func addTask(_ task: TaskModel) {
        tasks.append(task)
        tableView.reloadData()
    }
    
    // Метод для обработки нажатия на кнопку "Статистика"
    @objc func statButtonTapped() {
        let statisticsVC = StatisticsViewController()
        statisticsVC.restorationIdentifier = "settingsViewController"
        statisticsVC.modalPresentationStyle = .fullScreen
        statisticsVC.modalTransitionStyle = .crossDissolve
        present(statisticsVC, animated: true, completion: nil)
    }
}
