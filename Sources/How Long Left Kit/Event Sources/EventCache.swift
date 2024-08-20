//
//  EventCache.swift
//  How Long Left Kit
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit
import Combine
import os.log

public class EventCache: ObservableObject {
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EventCache")
    
    private var eventCache: [Event]?
    
    private weak var calendarReader: CalendarSource?
    private var stale = false
    
    
    private var eventStoreSubscription: AnyCancellable?
    private var hiddenEventManagerSubscription: AnyCancellable?
    private var calendarPrefsSubscription: AnyCancellable?
    
    private var calendarContexts: Set<String>
    
    let queue = DispatchQueue(label: "com.ryankontos.howlongleft_eventcachequeue")
    
    private weak var calendarProvider: (any EventFilteringOptionsProvider)? {
        didSet {
            setupCalendarsSubscription()
        }
    }
    
    private weak var hiddenEventManager: StoredEventManager? {
        didSet {
            setupHiddenEventManagerSubscription()
        }
    }
    
    public var id: String
    
    public init(calendarReader: CalendarSource?, calendarProvider: any EventFilteringOptionsProvider, calendarContexts: Set<String>, hiddenEventManager: StoredEventManager, id: String) {
        self.id = id
        self.calendarReader = calendarReader
        self.calendarProvider = calendarProvider
        self.calendarContexts = calendarContexts
        self.hiddenEventManager = hiddenEventManager
        setupEventStoreSubscription()
        setupCalendarsSubscription()
        setupHiddenEventManagerSubscription()
        updateEvents()
        
        
        
        while calendarReader?.authorization == .notDetermined { }
        
    }
    
    private func setupCalendarsSubscription() {
        
        guard let calendarProvider else { return }
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
        calendarPrefsSubscription = calendarProvider.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                
                self?.updateEvents()
            }
            
    }
    
    private func setupHiddenEventManagerSubscription() {
        
        guard let hiddenEventManager else { return }
        hiddenEventManagerSubscription?.cancel()
        hiddenEventManagerSubscription = nil
        hiddenEventManagerSubscription = hiddenEventManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
               
                self?.updateEvents()
            }
            
    }
    
    
    private func setupEventStoreSubscription() {
        
        guard let reader = calendarReader else { return }
        
        self.eventStoreSubscription?.cancel()
        self.eventStoreSubscription = nil
        
        eventStoreSubscription = NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: reader.eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.calendarProvider?.updateForNewCals()
                self?.updateEvents()
            }
            
    }
    
    func getEvents() -> [Event] {
        if eventCache == nil { updateEvents() }
        if stale { updateEvents() }
        return eventCache ?? []
    }
    
    private func updateEvents() {
        // Record start time
        let startTime = Date()
        
        //print("Updating events")
        
        guard let calendarProvider else {
            return
        }
        
        guard let calendarReader = self.calendarReader else { return }
        
        var foundChanges = false
        let oldCache = eventCache
        var newEventCache = [Event]()
        let newEvents = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }
        
        for ekEvent in newEvents {
            if let hiddenEventManager {
                if hiddenEventManager.isEventStoredWith(eventID: ekEvent.eventIdentifier) {
                    continue
                }
            }
            
            if var existingMatch = oldCache?.first(where: { ekEvent.id == $0.id }) {
                let changes = updateEvent(Event: &existingMatch, from: ekEvent)
                if changes { foundChanges = true }
                newEventCache.append(existingMatch)
            } else {
                foundChanges = true
                newEventCache.append(Event(event: ekEvent))
            }
        }
        
        if newEventCache != oldCache { foundChanges = true }
        stale = false
        
        if foundChanges {
            self.eventCache = newEventCache
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        // Record end time
        let endTime = Date()
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        // Print duration
        //print("Time taken to update events: \(timeInterval) seconds")
    }

    
    private func updateEvent(Event: inout Event, from ekEvent: EKEvent) -> Bool {
        
        var changes = false
     
        updateIfNeeded(&Event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&Event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&Event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        updateIfNeeded(&Event.calendarID, compareTo: ekEvent.calendar.calendarIdentifier, flag: &changes)
        updateIfNeeded(&Event.structuredLocation, compareTo: ekEvent.structuredLocation, flag: &changes)
        return changes
    }
    
    deinit {
        
        print("Eventcache deinit")
        
        eventStoreSubscription?.cancel()
        eventStoreSubscription = nil
        
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
    }
    
}
