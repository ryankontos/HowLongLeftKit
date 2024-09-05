import Foundation
import Defaults
import Combine
import EventKit
import CoreData
import os.log

public class EventFetchSettingsManager: ObservableObject {
  
    
    public struct Configuration: Sendable {
        public init(domain: String, defaultContextsForNonMatches: Set<String>) {
            self.domain = domain
            self.defaultContextsForNonMatches = defaultContextsForNonMatches
            self.allowAllDayKey = Defaults.Key<Bool>("HLL_EventFiltering_\(domain)_AllowAllDayEvents", default: true)
        }
        
        public let allowAllDayKey: Defaults.Key<Bool>
        
        var domain: String
        var defaultContextsForNonMatches: Set<String>
    }
    


    public var configuration: Configuration
    public var calendarItems: [CalendarInfo] = []
    
    private let calendarSource: CalendarSource
    private var domainObject: CalendarStorageDomain?
    private var cancellables: Set<AnyCancellable> = []
    
    private let logger: Logger
    
    private let context: HLLPersistenceController
    
    private var updateStream: AsyncStream<Void>!
    private var updateContinuation: AsyncStream<Void>.Continuation!
    
    public init(calendarSource: CalendarSource, config: Configuration, context: HLLPersistenceController) {
        self.configuration = config
        self.calendarSource = calendarSource
        self.context = context
        self.logger = Logger(subsystem: "howlongleftmac.eventfetchsettingsmanager", category: "\(config.domain)")
        
        self.updateStream = AsyncStream<Void> { continuation in
                    self.updateContinuation = continuation
                }
        
        
    }
    
    public func setup() async {
        
        fetchOrCreateDomainObject()
        syncCalendarsWithDomain()
        updateCalendarItems()
        updateSubscriptions()
       
       
        
    }
    
    private func notifyUpdate() {
            updateContinuation.yield()
        }

        public func updates() -> AsyncStream<Void> {
            return updateStream
        }
    
    private func fetchOrCreateDomainObject() {
        
        self.context.performBackgroundTask { con in
            
            
            let fetchRequest: NSFetchRequest<CalendarStorageDomain> = CalendarStorageDomain.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "domainID == %@", self.configuration.domain)
            
            do {
                let results = try con.fetch(fetchRequest)
                if let existingDomain = results.first {
                    self.domainObject = existingDomain
                } else {
                    let newDomain = CalendarStorageDomain(context: con)
                    newDomain.domainID = self.configuration.domain
                    self.domainObject = newDomain
                    
                }
            } catch {
                self.handleError(error, message: "Error fetching or saving domain object")
            }
            
        }
       
    }
    
    private func syncCalendarsWithDomain() {
        
        
        
        guard let domainObject = self.domainObject else { return }
        
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        
        let fetchRequest: NSFetchRequest<CalendarInfo> = CalendarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        
        do {
            let existingCalendarInfos = try self.context.getViewContext().fetch(fetchRequest)
            
            for ekCalendar in allCalendars {
                if let match = existingCalendarInfos.first(where: { $0.id == ekCalendar.calendarIdentifier }) ?? existingCalendarInfos.first(where: { $0.title == ekCalendar.title }) {
                    if match.id != ekCalendar.calendarIdentifier || match.title != ekCalendar.title {
                        match.id = ekCalendar.calendarIdentifier
                        match.title = ekCalendar.title
                    }
                } else {
                    let newCalendarInfo = CalendarInfo(context: self.context.getViewContext())
                    newCalendarInfo.id = ekCalendar.calendarIdentifier
                    newCalendarInfo.title = ekCalendar.title
                    newCalendarInfo.domain = domainObject

                    for context in configuration.defaultContextsForNonMatches {
                        let newContext = CalendarContext(context: self.context.getViewContext())
                        newContext.id = context
                        newContext.calendar = newCalendarInfo
                        newCalendarInfo.addToContexts(newContext)
                    }
                }
            }
            
            try self.context.getViewContext().save()
            updateCalendarItems()
        } catch {
            handleError(error, message: "Error syncing calendars with domain")
        }
    }
    
    private func updateCalendarItems() {
        guard let domainObject = self.domainObject else { return }
        
        let fetchRequest: NSFetchRequest<CalendarInfo> = CalendarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        
        do {
            let existingCalendarInfos = try self.context.getViewContext().fetch(fetchRequest)
            let allCalendars = calendarSource.eventStore.calendars(for: .event)
            let allowedCalendarIds = Set(allCalendars.map { $0.calendarIdentifier })
            
            var validCalendarInfos = existingCalendarInfos.filter { allowedCalendarIds.contains($0.id ?? "") }
            validCalendarInfos.sort { $0.title ?? "" < $1.title ?? "" }
            self.calendarItems = validCalendarInfos
           
            
            notifyUpdate()
            
            self.updateSubscriptions()
            
        } catch {
            handleError(error, message: "Error updating calendar items")
        }
    }
    
    public func getAllDayAllowed() -> Bool {
        return Defaults[configuration.allowAllDayKey]
    }
    
    private func updateSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
       /* calendarItems.forEach { calendarInfo in
            calendarInfo.objectWillChange
            
                .sink { [ _ in
                    
                    DispatchQueue.main.async {
                        //self?.calendarInfoDidChange(calendarInfo)
                    }
                }
                .store(in: &cancellables)
        } */
    }
    
    private func calendarInfoDidChange(_ calendarInfo: CalendarInfo) {
        syncCalendarsWithDomain()
        updateCalendarItems()
        notifyUpdate()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    
    public func fetchAllowedCalendarInfos(matchingContextIn contexts: Set<String>) throws -> [CalendarInfo] {

        
        
        guard let domainObject = self.domainObject else { return [] }
       
        let fetchRequest: NSFetchRequest<CalendarInfo> = CalendarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
       
        let existingCalendarInfos = try self.context.getViewContext().fetch(fetchRequest)
        let allowedCalendarInfos = existingCalendarInfos.filter { calendarInfo in
            guard let calendarContexts = calendarInfo.contexts as? Set<CalendarContext> else {
                return false
            }
            
            let calendarContextIds = calendarContexts.compactMap { $0.id }
            return contexts.isSubset(of: calendarContextIds)
        }
       
        return allowedCalendarInfos
    }

    
    public func getAllowedCalendars(matchingContextIn contexts: Set<String>) -> [EKCalendar] {
       // guard let domainObject = self.domainObject else { return [] }
        
        do {
            let allowedCalendarInfos = try fetchAllowedCalendarInfos(matchingContextIn: contexts)
            let allowedCalendarIds = Set(allowedCalendarInfos.compactMap { $0.id })
            
            let allCalendars = calendarSource.eventStore.calendars(for: .event)
            let cals = allCalendars.filter { allowedCalendarIds.contains($0.calendarIdentifier) }
            return cals
        } catch {
            handleError(error, message: "Error fetching allowed calendars")
            return []
        }
    }
    
    public func updateForNewCals() {
        
            syncCalendarsWithDomain()
        
    }
}

extension EventFetchSettingsManager {
    
    public func getEKCalendar(for calendarInfo: CalendarInfo) -> EKCalendar? {
            guard let calendarID = calendarInfo.id else {
                return nil
            }
            let allCalendars = calendarSource.eventStore.calendars(for: .event)
            return allCalendars.first { $0.calendarIdentifier == calendarID }
        }
    
    // Checks if a CalendarInfo object already contains a specific context ID
    public func containsContext(calendarInfo: CalendarInfo, contextID: String) -> Bool {
        guard let contexts = calendarInfo.contexts as? Set<CalendarContext> else { return false }
        return contexts.contains { $0.id == contextID }
    }
    
    public func containsContexts(calendarInfo: CalendarInfo, contextIDs: Set<String>) -> Bool {
        guard let contexts = calendarInfo.contexts as? Set<CalendarContext> else { return false }
        let contextIDsSet = Set(contextIDs)
        let matchingContextIDs = contexts.compactMap { $0.id }
        return contextIDsSet.isSubset(of: matchingContextIDs)
    }
    
    public func updateContexts(for calendarInfo: CalendarInfo, addContextIDs: Set<String>? = nil, removeContextIDs: Set<String>? = nil, notify: Bool = false) {
        guard self.domainObject != nil else { return }

        // Determine the contexts to actually add and remove, avoiding conflicts
        let actualAddContextIDs = addContextIDs?.subtracting(removeContextIDs ?? []) ?? []
        let actualRemoveContextIDs = removeContextIDs?.subtracting(addContextIDs ?? []) ?? []
        
        // Handle adding contexts
        for contextID in actualAddContextIDs {
            if containsContext(calendarInfo: calendarInfo, contextID: contextID) {
                //print("Context \(contextID) already exists in CalendarInfo \(calendarInfo.title ?? "unknown")")
                continue
            }

            let newContext = CalendarContext(context: self.context.getViewContext())
            newContext.id = contextID
            newContext.calendar = calendarInfo
            
            calendarInfo.addToContexts(newContext)
        }
        
        // Handle removing contexts
        if let contexts = calendarInfo.contexts as? Set<CalendarContext> {
            for contextID in actualRemoveContextIDs {
                if !containsContext(calendarInfo: calendarInfo, contextID: contextID) {
                    //print("Context \(contextID) does not exist in CalendarInfo \(calendarInfo.title ?? "unknown")")
                    continue
                }

                if let contextToRemove = contexts.first(where: { $0.id == contextID }) {
                    self.context.getViewContext().delete(contextToRemove)
                }
            }
        }
        
       
        
        if notify {
           
               
                self.saveContext()
                self.updateCalendarItems()
              //  print("Sending object will change for update update")
              
                //self.objectWillChange.send()
                
            
        }
        
    }
    
    public func batchUpdateContexts(addContextIDs: Set<String>? = nil, removeContextIDs: Set<String>? = nil) {
        
        for item in self.calendarItems {
            
            updateContexts(for: item, addContextIDs: addContextIDs, removeContextIDs: removeContextIDs, notify: false)
            
        }
        
        print("Batch updated contetxts")
        
     
            
            self.saveContext()
            self.updateCalendarItems()
           // print("Sending object will change for batch update")
            //self.objectWillChange.send()
            
        
            
        
    }



    
    // Helper method to save the context
    private func saveContext() {
        do {
            try self.context.getViewContext().save()
        } catch {
            handleError(error, message: "Error saving context")
        }
    }
    
    // Centralized error handling
    private func handleError(_ error: Error, message: String) {
        // Here we can use a logging framework or any error handling strategy
        //print("\(message): \(error)")
    }
}
