//
//  StoredEventManager.swift
//  How Long Left Kit
//
//  Created by Ryan on 22/6/2024.
//

import Foundation
@preconcurrency import CoreData

@MainActor
public class StoredEventManager: ObservableObject {
    
    let context: HLLPersistenceController
    
    private var domainObject: EventStorageDomain?
    
    private var domain: String = ""
    
    private var limit: Int?
    
    public init(domain: String, limit: Int? = nil, context: HLLPersistenceController) {
        self.domain = domain
        self.limit = limit
        self.context = context
        
       
        
        
    }
    
    public func removeEventFromStore(eventInfo: StoredEventInfo) {
       
        deleteEventInfo(matching: eventInfo.eventID)
        
       
            self.objectWillChange.send()
        
        
    }
    
    public func addEventToStore(event: Event, removeIfExists: Bool = false) {
        if removeIfExists {
            if let existingEventInfo = fetchEventInfo(matching: event.eventID) {
                removeEventFromStore(eventInfo: existingEventInfo)
                return // Return early after removing the existing event
            }
        } else if isEventStored(event: event) {
            // If removeIfExists is false and the event is already stored, return early to avoid duplicates
            return
        }

        if let limit = limit {
            if getAllStoredEvents().count >= limit {
                removeOldestEvent()
            }
        }

        createEventInfo(with: event)

        objectWillChange.send()
       
        
    }
    
    public func getAllStoredEvents() -> [StoredEventInfo] {
        guard let domainObject else { return [] }
        
        let fetchRequest: NSFetchRequest<StoredEventInfo> = StoredEventInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        
        
        
        do {
            let eventInfos = try context.getViewContext().fetch(fetchRequest)
            return eventInfos
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func isEventStored(event: Event) -> Bool {
        return isEventStoredWith(eventID: event.eventID)
    }
    
    func isEventStoredWith(eventID: String) -> Bool {
        return fetchEventInfo(matching: eventID) != nil
    }
    
    private func fetchOrCreateDomainObject() {
        let fetchRequest: NSFetchRequest<EventStorageDomain> = EventStorageDomain.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domainID == %@", domain)
        
        do {
            let results = try self.context.getViewContext().fetch(fetchRequest)
            if let existingDomain = results.first {
                self.domainObject = existingDomain
            } else {
                let newDomain = EventStorageDomain(context: self.context.getViewContext())
                newDomain.domainID = domain
                self.domainObject = newDomain
                try self.context.getViewContext().save()
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func purge() {
        guard let items = domainObject?.eventInfos as? [StoredEventInfo] else { return }
        
        for info in items {
            context.getViewContext().delete(info)
        }
        
        try? context.getViewContext().save()
    }
    
    // Create HiddenEventInfo
    private func createEventInfo(with event: Event) {
        
        let newHiddenEventInfo = StoredEventInfo(context: context.getViewContext())
        newHiddenEventInfo.eventID = event.eventID
        newHiddenEventInfo.domain = domainObject
        newHiddenEventInfo.title = event.title
        newHiddenEventInfo.calendarID = event.calendarID
        newHiddenEventInfo.startDate = event.startDate
        newHiddenEventInfo.endDate = event.endDate
        newHiddenEventInfo.isAllDay = event.isAllDay
        newHiddenEventInfo.domain = domainObject
        newHiddenEventInfo.storedDate = Date()
        
        domainObject?.addToEventInfos(newHiddenEventInfo)
        
        context.getViewContext().insert(newHiddenEventInfo)
        
        do {
            try context.getViewContext().save()
        } catch {
            print("Failed to save new HiddenEventInfo: \(error)")
        }
    }
    
    // Fetch HiddenEventInfo matching the eventID
    func fetchEventInfo(matching eventId: String?) -> StoredEventInfo? {
        
        guard let eventId else { return nil }
        
        guard let domainObject else { return nil }
        
        let fetchRequest: NSFetchRequest<StoredEventInfo> = StoredEventInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "domain == %@ AND eventID == %@", domainObject, eventId)
        
        do {
            let eventInfos = try context.getViewContext().fetch(fetchRequest)
            return eventInfos.first
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // Delete HiddenEventInfo
    func deleteEventInfo(matching eventId: String?) {
        guard let hiddenEventInfo = fetchEventInfo(matching: eventId) else { return }
        context.getViewContext().delete(hiddenEventInfo)
        
        do {
            try context.getViewContext().save()
        } catch {
            print("Failed to delete HiddenEventInfo: \(error)")
        }
    }
    
    // Remove the oldest event based on storedDate
    private func removeOldestEvent() {
        guard let domainObject else { return }
        
        let fetchRequest: NSFetchRequest<StoredEventInfo> = StoredEventInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "storedDate", ascending: true)]
        fetchRequest.fetchLimit = 1
        
        do {
            let oldestEventInfos = try context.getViewContext().fetch(fetchRequest)
            if let oldestEventInfo = oldestEventInfos.first {
                context.getViewContext().delete(oldestEventInfo)
                try context.getViewContext().save()
            }
        } catch {
            print("Failed to remove oldest HiddenEventInfo: \(error)")
        }
    }
}
