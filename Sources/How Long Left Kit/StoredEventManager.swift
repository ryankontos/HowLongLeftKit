//
//  StoredEventManager.swift
//  How Long Left Kit
//
//  Created by Ryan on 22/6/2024.
//

import Foundation
import CoreData

public class StoredEventManager: ObservableObject {
    
    let context = HLLPersistenceController.shared.viewContext
    
    private var domainObject: EventInfoStorageDomain?
    
    private var domain: String = ""
    
    init(domain: String) {
        self.domain = domain
        fetchOrCreateDomainObject()
    }
    
   public func setEventHidden(event: Event, hidden: Bool) {
        
        do {
            let eventInfo = try fetchOrCreateEventInfo(matching: event.eventIdentifier)
            eventInfo.isHidden = hidden
            try self.context.save()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
        
    }
    
    public func setEventPinned(event: Event, pinned: Bool) {
        
        do {
            let eventInfo = try fetchOrCreateEventInfo(matching: event.eventIdentifier)
            eventInfo.isPinned = pinned
            try self.context.save()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            
        }
        
        
    }
    
    func isEventHidden(eventId: String) -> Bool {
        guard let object = try? fetchOrCreateEventInfo(matching: eventId) else { return false }
        return object.isHidden
    }
    
    func isEventPinned(eventId: String) -> Bool {
        guard let object = try? fetchOrCreateEventInfo(matching: eventId) else { return false }
        return object.isPinned
    }
    
    private func fetchOrCreateDomainObject() {
        let fetchRequest: NSFetchRequest<EventInfoStorageDomain> = EventInfoStorageDomain.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domainID == %@", domain)
        
        do {
            let results = try self.context.fetch(fetchRequest)
            if let existingDomain = results.first {
                self.domainObject = existingDomain
            } else {
                let newDomain = EventInfoStorageDomain(context: self.context)
                newDomain.domainID = domain
                self.domainObject = newDomain
                try self.context.save()
            }
        } catch {
           // handleError(error, message: "Error fetching or saving domain object")
        }
    }
    
    // Fetch or create EventInfo
    func fetchOrCreateEventInfo(matching eventID: String) throws -> EventInfo {
        if let eventInfo = fetchEventInfo(matching: eventID) {
            return eventInfo
        } else {
            return createEventInfo(with: eventID)
        }
    }
    
    // Fetch EventInfo matching the eventID
    func fetchEventInfo(matching eventID: String) -> EventInfo? {
        
        guard let domainObject else { return nil }
        
        let fetchRequest: NSFetchRequest<EventInfo> = EventInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "domain == %@ AND eventID == %@", domainObject, eventID)
        
        do {
            let eventInfos = try context.fetch(fetchRequest)
            return eventInfos.first
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // Create a new EventInfo
    func createEventInfo(with eventID: String) -> EventInfo {
        let newEventInfo = EventInfo(context: context)
        newEventInfo.eventID = eventID
        newEventInfo.domain = domainObject
        domainObject!.addToEventInfos(newEventInfo)
        
        print("Creating event info")
        
        do {
            try context.save()
        } catch {
            print("Failed to save new EventInfo: \(error)")
        }
        
        return newEventInfo
    }

    
    

    
}
