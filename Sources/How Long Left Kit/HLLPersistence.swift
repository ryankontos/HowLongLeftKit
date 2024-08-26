//
//  HLLPersistence.swift
//  How Long Left
//
//  Created by Ryan on 14/5/2024.
//

import Foundation
import CoreData

@MainActor
public class HLLPersistenceController {
    //static let shared = HLLPersistenceController()

    public let persistentContainer: NSPersistentCloudKitContainer
    private let backgroundContext: NSManagedObjectContext

    public init() {
        guard let modelURL = Bundle.module.url(forResource: "HowLongLeftDataModel", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to locate or load Core Data model")
        }

        persistentContainer = NSPersistentCloudKitContainer(name: "HowLongLeftDataModel", managedObjectModel: managedObjectModel)
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        backgroundContext = persistentContainer.newBackgroundContext()
    }

    public func getViewContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
  

    public func saveContext() {
        saveContext(context: context)
    }

    public func saveBackgroundContext() {
        saveContext(context: backgroundContext)
    }

    private func saveContext(context: NSManagedObjectContext) {
        context.perform {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }

    public func fetchEntities<T: NSManagedObject>(entityName: String, sortDescriptors: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) async -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate

        do {
            return try context.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }

    public func deleteEntity(_ entity: NSManagedObject) {
        context.perform {
            self.context.delete(entity)
            self.saveContext()
        }
    }

    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            self.saveContext(context: context)
        }
    }
}
