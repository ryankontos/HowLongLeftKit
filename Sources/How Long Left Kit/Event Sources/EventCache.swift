//
//  EventCache.swift
//  How Long Left Kit
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit
@preconcurrency import Combine
import os.log
import CryptoKit
import Defaults
import SwiftUI

@MainActor
public class EventCache: ObservableObject {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EventCache")
    
    private var eventCache: [HLLEvent]?
    public var cacheSummaryHash: String?
    
    private var stale = false
    private var calendarContexts: Set<String>
    
    private var eventStoreSubscription: AnyCancellable?
    private var hiddenEventManagerSubscription: AnyCancellable?
    private var calendarPrefsSubscription: AnyCancellable?
    
    private var fetchDataKey: Defaults.Key<String?>
    
    private var updatesCache: Bool
    
    private weak var calendarReader: CalendarSource?
    public weak var calendarProvider: (any EventFilteringOptionsProvider)? {
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
        
     /*   eventStoreSubscription?.cancel()
        eventStoreSubscription = NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: reader.eventStore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                //print("Event store changed")
                self?.calendarProvider?.updateForNewCals()
              
                DispatchQueue.main.async {
                    self?.updateEvents()
                }
                
            } */
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
    
    func getEvents() async -> [HLLEvent] {
        if eventCache == nil || stale {
            updateEvents()
        }
        return eventCache ?? []
    }
    
    public func getAllowedCalendars() -> [HLLCalendar]? {
        return calendarProvider?.getAllowedCalendars(matchingContextIn: calendarContexts)
    }
    
    private func updateEvents() {
        guard let calendarProvider, let calendarReader, let hiddenEventManager else { return }

        // Fetch new events
        let fetchResult = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))
        let newEvents = fetchResult.events
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }

        var newEventCache = [HLLEvent]()
        var foundChanges = false

        // Iterate through new events and update or add them
        for sourceNewEvent in newEvents {
            
            let eventID = sourceNewEvent.eventIdentifier
            
            if hiddenEventManager.isEventStoredWith(eventID: eventID) {
                foundChanges = true
                continue
            }

            // Check if the event already exists in the cache
            if let index = eventCache?.firstIndex(where: { $0.eventIdentifier == eventID }) {
                // Update the existing event
                var existingEvent = eventCache![index]
                let changes = updateEvent(&existingEvent, from: sourceNewEvent)
                foundChanges = foundChanges || changes
                newEventCache.append(existingEvent)
            } else {
                // Add new event
                foundChanges = true
                newEventCache.append(sourceNewEvent)
            }
        }

        // Detect deletions by checking for events in the old cache that are not in the new events
        if let oldEventCache = eventCache {
            for oldEvent in oldEventCache where !newEvents.contains(where: { $0.eventIdentifier == oldEvent.eventIdentifier }) {
                foundChanges = true
                logger.debug("Event deleted: \(oldEvent.eventIdentifier)")
            }
        }

        // Update the cache if there are changes
        if foundChanges {
            eventCache = newEventCache
            cacheSummaryHash = String(fetchResult.getHash())
            stale = false
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }


    public func calculateHash(for dates: [Date]) -> String {
        let concatenatedDates = dates.map { String($0.timeIntervalSinceReferenceDate) }.joined(separator: " ")
        let hashedData = SHA256.hash(data: concatenatedDates.data(using: .utf8)!)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    private func updateEvent(_ event: inout HLLEvent, from ekEvent: HLLEvent) -> Bool {
        var changes = false
        updateIfNeeded(&event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        updateIfNeeded(&event.calendar, compareTo: ekEvent.calendar, flag: &changes)
        updateIfNeeded(&event.structuredLocation, compareTo: ekEvent.structuredLocation, flag: &changes)
        #if os(macOS)
        event.setColor(color: event.color)
        #else
        event.setColor(color: event.color)
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
