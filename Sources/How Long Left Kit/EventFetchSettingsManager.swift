import Foundation
import Defaults
import Combine
import EventKit
import CoreData

public class EventFetchSettingsManager: ObservableObject, EventFilteringOptionsProvider {
  
    
    public struct Configuration {
        public init(domain: String, defaultContextsForNonMatches: Set<String>) {
            self.domain = domain
            self.defaultContextsForNonMatches = defaultContextsForNonMatches
            self.allowAllDayKey = Defaults.Key<Bool>("HLL_EventFiltering_\(domain)_AllowAllDayEvents", default: true)
        }
        
        public let allowAllDayKey: Defaults.Key<Bool>
        
        var domain: String
        var defaultContextsForNonMatches: Set<String>
    }
    
    static let context = HLLPersistenceController.shared.viewContext

    @Published public var configuration: Configuration
    @Published public var calendarItems: [CalendarInfo] = []
    
    private let calendarSource: CalendarSource
    private var domainObject: CalendarStorageDomain?
    private var cancellables: Set<AnyCancellable> = []
    
    init(calendarSource: CalendarSource, config: Configuration) {
        self.configuration = config
        self.calendarSource = calendarSource
        fetchOrCreateDomainObject()
        syncCalendarsWithDomain()
        updateCalendarItems()
        updateSubscriptions()
        
        Task {
            for await _ in Defaults.updates(config.allowAllDayKey) {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
        
    }
    
    private func fetchOrCreateDomainObject() {
        let fetchRequest: NSFetchRequest<CalendarStorageDomain> = CalendarStorageDomain.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domainID == %@", configuration.domain)
        
        do {
            let results = try Self.context.fetch(fetchRequest)
            if let existingDomain = results.first {
                self.domainObject = existingDomain
            } else {
                let newDomain = CalendarStorageDomain(context: Self.context)
                newDomain.domainID = configuration.domain
                self.domainObject = newDomain
                try Self.context.save()
            }
        } catch {
            handleError(error, message: "Error fetching or saving domain object")
        }
    }
    
    private func syncCalendarsWithDomain() {
        guard let domainObject = self.domainObject else { return }
        
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        
        let fetchRequest: NSFetchRequest<CalendarInfo> = CalendarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        
        do {
            let existingCalendarInfos = try Self.context.fetch(fetchRequest)
            
            for ekCalendar in allCalendars {
                if let match = existingCalendarInfos.first(where: { $0.id == ekCalendar.calendarIdentifier }) ?? existingCalendarInfos.first(where: { $0.title == ekCalendar.title }) {
                    if match.id != ekCalendar.calendarIdentifier || match.title != ekCalendar.title {
                        match.id = ekCalendar.calendarIdentifier
                        match.title = ekCalendar.title
                    }
                } else {
                    let newCalendarInfo = CalendarInfo(context: Self.context)
                    newCalendarInfo.id = ekCalendar.calendarIdentifier
                    newCalendarInfo.title = ekCalendar.title
                    newCalendarInfo.domain = domainObject

                    for context in configuration.defaultContextsForNonMatches {
                        let newContext = CalendarContext(context: Self.context)
                        newContext.id = context
                        newContext.calendar = newCalendarInfo
                        newCalendarInfo.addToContexts(newContext)
                    }
                }
            }
            
            try Self.context.save()
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
            let existingCalendarInfos = try Self.context.fetch(fetchRequest)
            let allCalendars = calendarSource.eventStore.calendars(for: .event)
            let allowedCalendarIds = Set(allCalendars.map { $0.calendarIdentifier })
            
            let validCalendarInfos = existingCalendarInfos.filter { allowedCalendarIds.contains($0.id ?? "") }
            self.calendarItems = validCalendarInfos
            updateSubscriptions()
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
        
        calendarItems.forEach { calendarInfo in
            calendarInfo.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.calendarInfoDidChange(calendarInfo)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func calendarInfoDidChange(_ calendarInfo: CalendarInfo) {
        syncCalendarsWithDomain()
        updateCalendarItems()
        objectWillChange.send()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    public func getAllowedCalendars(matchingContextIn contexts: Set<String>) -> [EKCalendar] {
        guard let domainObject = self.domainObject else { return [] }
        
        let fetchRequest: NSFetchRequest<CalendarInfo> = CalendarInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "domain == %@", domainObject)
        
        do {
            let existingCalendarInfos = try Self.context.fetch(fetchRequest)
            let allowedCalendarInfos = existingCalendarInfos.filter { calendarInfo in
                return calendarInfo.contexts?.contains { context in
                    guard let context = context as? CalendarContext else { return false }
                    return contexts.contains(context.id ?? "")
                } ?? false
            }
            
            let allowedCalendarIds = Set(allowedCalendarInfos.compactMap { $0.id })
            //print("Returning \(allowedCalendarIds.count) cals")
            let allCalendars = calendarSource.eventStore.calendars(for: .event)
            
            return allCalendars.filter { allowedCalendarIds.contains($0.calendarIdentifier) }
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
    
    public func updateContexts(for calendarInfo: CalendarInfo, addContextIDs: Set<String>? = nil, removeContextIDs: Set<String>? = nil) {
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

            let newContext = CalendarContext(context: Self.context)
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
                    Self.context.delete(contextToRemove)
                }
            }
        }
        
        saveContext()
        updateCalendarItems()
    }



    
    // Helper method to save the context
    private func saveContext() {
        do {
            try Self.context.save()
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
