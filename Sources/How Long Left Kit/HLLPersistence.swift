//
//  HLLPersistence.swift
//  How Long Left
//
//  Created by Ryan on 14/5/2024.
//

import Foundation
import CoreData

public class HLLPersistenceController {
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
    
    private func getMainContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    public func saveContext() {
        saveContext(context: getMainContext())
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



    public func deleteEntity(_ entity: NSManagedObject) {
        getMainContext().perform {
            self.getMainContext().delete(entity)
            self.saveContext(context: self.getMainContext())
        }
    }

    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            self.saveContext(context: context)
        }
    }
}
