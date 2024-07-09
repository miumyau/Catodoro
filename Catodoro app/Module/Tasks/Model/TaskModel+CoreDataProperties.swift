import Foundation
import CoreData
extension TaskModel {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskModel> {
        return NSFetchRequest<TaskModel>(entityName: "TaskModel")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var taskReadiness: Bool
    @NSManaged public var shortRestDuration: Int32
    @NSManaged public var sessionNumber: Int32
    @NSManaged public var sessionDuration: Int32
    @NSManaged public var longRestDuration: Int32
    @NSManaged public var readinessNumber: Int32
    @NSManaged public var longRestTime: Int32
    @NSManaged public var taskDate: Date?
    @NSManaged public var canNotify: Bool
}

extension TaskModel : Identifiable {
    
}
extension TaskModel {
    convenience init(title: String?, subtitle: String?, taskReadiness: Bool,readinessNumber: Int32, shortRestDuration: Int32, sessionNumber: Int32, sessionDuration: Int32, longRestDuration: Int32, longRestTime: Int32, taskDate: Date?, canNotify: Bool, context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = title
        self.subtitle = subtitle
        self.taskReadiness = taskReadiness
        self.readinessNumber = readinessNumber
        self.shortRestDuration = shortRestDuration
        self.sessionNumber = sessionNumber
        self.sessionDuration = sessionDuration
        self.longRestDuration = longRestDuration
        self.longRestTime = longRestTime
        self.taskDate = taskDate
        self.canNotify = canNotify       
        self.id = UUID()
        
    }
}
