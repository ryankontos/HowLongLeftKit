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
    private var calendarPrefsSubscription: AnyCancellable?
    
    
    private weak var preferenceManager: CalendarPreferenceManager? {
        didSet {
            setupCalendarsSubscription()
        }
    }
    
    public init(calendarReader: CalendarSource, preferenceManager: CalendarPreferenceManager) {
        self.calendarReader = calendarReader
        self.preferenceManager = preferenceManager
        setupEventStoreSubscription()
        setupCalendarsSubscription()
        updateEvents()
    }
    
    private func setupCalendarsSubscription() {
        
        guard let preferenceManager else { return }
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
        calendarPrefsSubscription = preferenceManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("Cals changed")
                self?.updateEvents()
            }
            
    }
    
    
    private func setupEventStoreSubscription() {
        
        self.eventStoreSubscription?.cancel()
        self.eventStoreSubscription = nil
        
        eventStoreSubscription = NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: calendarReader.eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
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
            
        var foundChanges = false
        let oldCache = eventCache
        var newEventCache = [Event]()
        let newEvents = calendarReader.getEvents(from: preferenceManager!.getEKCalendars(withMode: .global))
       
        for ekEvent in newEvents {
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
            DispatchQueue.main.async {
                self.eventCache = newEventCache
                self.objectWillChange.send()
            }
        }
    }
    
    private func updateEvent(Event: inout Event, from ekEvent: EKEvent) -> Bool {
        var changes = false
        updateIfNeeded(&Event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&Event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&Event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        return changes
    }
    
    deinit {
        eventStoreSubscription?.cancel()
        eventStoreSubscription = nil
        
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = nil
    }
    
}
