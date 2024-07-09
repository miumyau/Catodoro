import UIKit
import CoreData
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var tasksViewController: TasksViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Создаем window
        let tasksVC = TasksViewController()
        self.tasksViewController = tasksVC
        print("TasksViewController создан")
        
        // Создание корневого контроллера
        let mainVC = MainViewController(tasksViewController: tasksVC)
        print("TasksViewController передан в MainViewController")
        
        let navigationController = UINavigationController(rootViewController: mainVC)
        
        // Устанавливаем корневой контроллер
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        print("Корневой контроллер установлен")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Разрешение на отправку уведомлений получено.")
            } else {
                print("Разрешение на отправку уведомлений отклонено.")
            }
        }
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TaskModel") // Имя должно совпадать с именем вашего файла .xcdatamodeld без расширения
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // Метод для поиска TasksViewController в иерархии
    func findTasksViewController(_ rootViewController: UIViewController) -> TasksViewController? {
        if let tasksVC = rootViewController as? TasksViewController {
            return tasksVC
        }
        for child in rootViewController.children {
            if let tasksVC = findTasksViewController(child) {
                return tasksVC
            }
        }
        return nil
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
}
