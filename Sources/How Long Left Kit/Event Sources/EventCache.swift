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
import CryptoKit
import Defaults
import SwiftUI

public class EventCache: ObservableObject {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EventCache")
    
    private var eventCache: [Event]?
    public var cacheSummaryHash: String?
    
    private var stale = false
    private var calendarContexts: Set<String>
    
    private var eventStoreSubscription: AnyCancellable?
    private var hiddenEventManagerSubscription: AnyCancellable?
    private var calendarPrefsSubscription: AnyCancellable?
    
    private var fetchDataKey: Defaults.Key<String?>
    
    private var updatesCache: Bool
    
    private weak var calendarReader: CalendarSource?
    private weak var calendarProvider: (any EventFilteringOptionsProvider)? {
        didSet { setupCalendarsSubscription() }
    }
    private weak var hiddenEventManager: StoredEventManager? {
        didSet { setupHiddenEventManagerSubscription() }
    }
    
    let queue = DispatchQueue(label: "com.ryankontos.howlongleft_eventcachequeue")
    
    public var id: String
    
    public init(calendarReader: CalendarSource?,
                calendarProvider: any EventFilteringOptionsProvider,
                calendarContexts: Set<String>,
                hiddenEventManager: StoredEventManager,
                id: String, updatesCache: Bool = false) {
        
        self.calendarReader = calendarReader
        self.calendarProvider = calendarProvider
        self.calendarContexts = calendarContexts
        self.hiddenEventManager = hiddenEventManager
        self.id = id
        
        self.updatesCache = updatesCache
        
        fetchDataKey = Defaults.Key<String?>("\(id)_LatestFetchData", suite: sharedDefaults, default: { nil })
        
        setupSubscriptions()
        Task {
            updateEvents()
        }
        
        
        //waitForAuthorization()
    }
    
    // MARK: - Setup Functions
    
    private func setupSubscriptions() {
        setupEventStoreSubscription()
        setupCalendarsSubscription()
        setupHiddenEventManagerSubscription()
    }
    
    private func setupEventStoreSubscription() {
        guard let reader = calendarReader else { return }
        
        eventStoreSubscription?.cancel()
        eventStoreSubscription = NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: reader.eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                //print("Event store changed")
                self?.calendarProvider?.updateForNewCals()
              
                DispatchQueue.main.async {
                    self?.updateEvents()
                }
                
            }
    }
    
    private func setupCalendarsSubscription() {
        guard let calendarProvider else { return }
        
        calendarPrefsSubscription?.cancel()
        calendarPrefsSubscription = calendarProvider.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                
                DispatchQueue.main.async {
                    
                    self?.updateEvents()
                }
                
            }
    }
    
    private func setupHiddenEventManagerSubscription() {
        guard let hiddenEventManager else { return }
        
        hiddenEventManagerSubscription?.cancel()
        hiddenEventManagerSubscription = hiddenEventManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [self] in
                self.updateEvents()
            }
    }
    
    private func waitForAuthorization() {
        while calendarReader?.authorization == .notDetermined { }
    }
    
    // MARK: - Event Update Logic
    
    func getEvents() async -> [Event] {
        if eventCache == nil || stale {
            updateEvents()
        }
        return eventCache ?? []
    }
    
   
    private func updateEvents() {
        guard let calendarProvider, let calendarReader else { return }

        // Fetch new events
        let fetchResult = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))
        let newEvents = fetchResult.events
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }

        // Create a dictionary for new events keyed by their ID
        let newEventsDict = Dictionary(uniqueKeysWithValues: newEvents.map { ($0.id, $0) })
        
        // Create a dictionary for the current cache keyed by event ID
        let oldEventsDict = eventCache?.reduce(into: [String: Event]()) { $0[$1.id] = $1 } ?? [:]

        var newEventCache = [Event]()
        var foundChanges = false

        // Update existing events and add new events
        for (eventID, ekEvent) in newEventsDict {
            if var existingEvent = oldEventsDict[eventID] {
                let changes = updateEvent(&existingEvent, from: ekEvent)
                foundChanges = foundChanges || changes
                newEventCache.append(existingEvent)
            } else {
                foundChanges = true
                let newEvent = Event(event: ekEvent)
                #if os(macOS)
                newEvent.setColor(color: Color(ekEvent.calendar.color))
                #else
                newEvent.setColor(color: Color(ekEvent.calendar.cgColor))
                #endif
                newEventCache.append(newEvent)
            }
        }

        // Detect deletions by checking for events in old cache that are not in newEventsDict
        for oldEventID in oldEventsDict.keys where newEventsDict[oldEventID] == nil {
            foundChanges = true
            logger.debug("Event deleted: \(oldEventID)")
        }

        // Update the cache if there are changes
        if foundChanges {
            eventCache = newEventCache
            cacheSummaryHash = String(fetchResult.getHash())
            stale = false
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }

    private func calculateHash(for dates: [Date]) -> String {
        let concatenatedDates = dates.map { String($0.timeIntervalSinceReferenceDate) }.joined(separator: " ")
        let hashedData = SHA256.hash(data: concatenatedDates.data(using: .utf8)!)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    private func updateEvent(_ event: inout Event, from ekEvent: EKEvent) -> Bool {
        var changes = false
        updateIfNeeded(&event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        updateIfNeeded(&event.calendarID, compareTo: ekEvent.calendar.calendarIdentifier, flag: &changes)
        updateIfNeeded(&event.structuredLocation, compareTo: ekEvent.structuredLocation, flag: &changes)
        #if os(macOS)
        event.setColor(color: Color(ekEvent.calendar.color))
        #else
        event.setColor(color: Color(ekEvent.calendar.cgColor))
        #endif
        return changes
    }
    
    deinit {
        eventStoreSubscription?.cancel()
        calendarPrefsSubscription?.cancel()
        hiddenEventManagerSubscription?.cancel()
        logger.debug("EventCache deinitialized")
    }
}
