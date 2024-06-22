//
//  EventCache.swift
//  How Long Left Kit
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit
import Combine

public class EventCache: ObservableObject {
    
    private var eventCache: [Event]?
    
    private let calendarReader: CalendarSource
    private var stale = false
    
    
    private var eventStoreSubscription: AnyCancellable?
    private var storedEventManagerSubscription: AnyCancellable?
    private var calendarPrefsSubscription: AnyCancellable?
    
    private var calendarContexts: Set<String>
    
    private weak var calendarProvider: (any EventFilteringOptionsProvider)? {
        didSet {
            setupCalendarsSubscription()
        }
    }
    
    private weak var storedEventManager: StoredEventManager? {
        didSet {
            setupStoredEventManagerSubscription()
        }
    }
    
    public init(calendarReader: CalendarSource, calendarProvider: any EventFilteringOptionsProvider, calendarContexts: Set<String>, storedEventManager: StoredEventManager) {
        self.calendarReader = calendarReader
        self.calendarProvider = calendarProvider
        self.calendarContexts = calendarContexts
        self.storedEventManager = storedEventManager
        setupEventStoreSubscription()
        setupCalendarsSubscription()
        setupStoredEventManagerSubscription()
        updateEvents()
        
        while calendarReader.authorization == .notDetermined { }
        
    }
    
    private func setupCalendarsSubscription() {
        
        guard let calendarProvider else { return }
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
        calendarPrefsSubscription = calendarProvider.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                //print("Cals changed")
                self?.updateEvents()
            }
            
    }
    
    private func setupStoredEventManagerSubscription() {
        
        guard let storedEventManager else { return }
        storedEventManagerSubscription?.cancel()
        storedEventManagerSubscription = nil
        storedEventManagerSubscription = storedEventManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                //print("Cals changed")
                self?.updateEvents()
            }
            
    }
    
    
    private func setupEventStoreSubscription() {
        
        self.eventStoreSubscription?.cancel()
        self.eventStoreSubscription = nil
        
        eventStoreSubscription = NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: calendarReader.eventStore)
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
        
        print("Updating events")
            
        guard let calendarProvider else {
            return
        }
        
        var foundChanges = false
        let oldCache = eventCache
        var newEventCache = [Event]()
        let newEvents = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }

        
        for ekEvent in newEvents {
            
            let eventInfo = storedEventManager!.fetchEventInfo(matching: ekEvent.eventIdentifier)
            
            if let eventInfo {
                print("Found event info")
                if eventInfo.isHidden {
                    foundChanges = true
                    continue
                }
            }
            
            if var existingMatch = oldCache?.first(where: { ekEvent.id == $0.id }) {
                let changes = updateEvent(Event: &existingMatch, from: ekEvent, eventInfo: eventInfo)
                if changes { foundChanges = true }
                newEventCache.append(existingMatch)
            } else {
                foundChanges = true
                newEventCache.append(Event(event: ekEvent, eventInfo: eventInfo))
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
    }
    
    private func updateEvent(Event: inout Event, from ekEvent: EKEvent, eventInfo: EventInfo?) -> Bool {
        
        var changes = false
        
        if let eventInfo {
            updateIfNeeded(&Event.isHidden, compareTo: eventInfo.isHidden, flag: &changes)
            updateIfNeeded(&Event.isPinned, compareTo: eventInfo.isPinned, flag: &changes)
        }
        
        updateIfNeeded(&Event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&Event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&Event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        updateIfNeeded(&Event.calId, compareTo: ekEvent.calendar.calendarIdentifier, flag: &changes)
        updateIfNeeded(&Event.structuredLocation, compareTo: ekEvent.structuredLocation, flag: &changes)
        return changes
    }
    
    deinit {
        eventStoreSubscription?.cancel()
        eventStoreSubscription = nil
        
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
    }
    
}
