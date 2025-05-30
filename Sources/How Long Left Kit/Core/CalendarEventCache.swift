//
//  CalendarEventCache.swift
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
public class CalendarEventCache: ObservableObject {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "EventCache")
    
    private var eventCache: [HLLCalendarEvent]?
    public var cacheSummaryHash: String?
    
    private var stale = false
    private var calendarContexts: Set<String>
    
    private var eventStoreSubscription: AnyCancellable?
    private var hiddenEventManagerSubscription: AnyCancellable?
    private var calendarPrefsSubscription: AnyCancellable?
    private var calendarSourceSubscription: AnyCancellable?
    
    private var fetchDataKey: Defaults.Key<String?>
    
    private var updatesCache: Bool
    
    private weak var calendarReader: CalendarSource?
    public weak var calendarProvider: (any CalendarSettingsProvider)? {
        didSet { setupCalendarsSubscription() }
    }
    private weak var hiddenEventManager: StoredEventManager? {
        didSet { setupHiddenEventManagerSubscription() }
    }
    
    let queue = DispatchQueue(label: "com.ryankontos.howlongleft_eventcachequeue")
    
    public var id: String
    
    public init(calendarReader: CalendarSource?,
                calendarProvider: any CalendarSettingsProvider,
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
    }
    
    // MARK: - Setup Functions
    
    private func setupSubscriptions() {
        setupCalendarsSubscription()
        setupHiddenEventManagerSubscription()
        setupCalendarSourceSubscription()
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
            .sink { [weak self] in
                self?.updateEvents()
            }
    }
    
    private func setupCalendarSourceSubscription() {
        guard let reader = calendarReader else { return }
        calendarSourceSubscription?.cancel()
        calendarSourceSubscription = reader.eventChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.logger.debug("Received eventChanged notification from CalendarSource")
                self?.updateEvents()
            }
    }
    
    // MARK: - Event Update Logic
    
    func getEvents() async -> [HLLCalendarEvent] {
        if eventCache == nil || stale {
            updateEvents()
        }
        return eventCache ?? []
    }
    
    public func getAllowedCalendars() -> [HLLCalendar]? {
        return calendarProvider?.getAllowedCalendars(matchingContextIn: calendarContexts)
    }
    
    private func updateEvents() {
        
        //print("Updating events")
        
        let oldEventCache = eventCache
        
        guard let calendarProvider, let calendarReader, let hiddenEventManager else { return }

        //calendarProvider.updateForNewCals()
        
        // Fetch new events
        let fetchResult = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))

        let newEvents = fetchResult.events
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }

        var newEventCache = [HLLCalendarEvent]()

        // Iterate through new events and update or add them
        for sourceNewEvent in newEvents {
            let eventID = sourceNewEvent.eventIdentifier
            
            if hiddenEventManager.isEventStoredWith(eventID: eventID) {
                continue
            }

            newEventCache.append(sourceNewEvent)
            
        }

       
        
        // Update the cache if there are changes
        if oldEventCache != newEventCache {
           
            eventCache = newEventCache
            cacheSummaryHash = String(fetchResult.getHash())
            stale = false
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }
    
    private func updateEvent(_ event: inout HLLCalendarEvent, from ekEvent: HLLCalendarEvent) -> Bool {
        var changes = false
        updateIfNeeded(&event.title, compareTo: ekEvent.title, flag: &changes)
        updateIfNeeded(&event.startDate, compareTo: ekEvent.startDate, flag: &changes)
        updateIfNeeded(&event.endDate, compareTo: ekEvent.endDate, flag: &changes)
        updateIfNeeded(&event.calendar, compareTo: ekEvent.calendar, flag: &changes)
        updateIfNeeded(&event.structuredLocation, compareTo: ekEvent.structuredLocation, flag: &changes)
        return changes
    }
    
    deinit {
        calendarPrefsSubscription?.cancel()
        hiddenEventManagerSubscription?.cancel()
        calendarSourceSubscription?.cancel()
        logger.debug("EventCache deinitialized")
    }
}
