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
            await updateEvents()
        }
        
        
        waitForAuthorization()
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
            .receive(on: DispatchQueue.global())
            .sink { [weak self] _ in
                print("Event store changed")
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
            await updateEvents()
        }
        return eventCache ?? []
    }
    
   
    
    private func updateEvents() {
        guard let calendarProvider, let calendarReader else { return }
        
        var foundChanges = false
        let oldCache = eventCache
        var newEventCache = [Event]()
        let fetchResult = calendarReader.getEvents(from: calendarProvider.getAllowedCalendars(matchingContextIn: calendarContexts))
        
        
        let newEvents = fetchResult.events
            .filter { event in calendarProvider.getAllDayAllowed() || !event.isAllDay }
        
     
        
        for ekEvent in newEvents {
            if var existingEvent = oldCache?.first(where: { ekEvent.id == $0.id }) {
                let changes = updateEvent(&existingEvent, from: ekEvent)
                foundChanges = foundChanges || changes
                newEventCache.append(existingEvent)
            } else {
                foundChanges = true
                newEventCache.append(Event(event: ekEvent))
            }
        }
        
        let hashString = String(fetchResult.getHash())
        
        
        
        if foundChanges {
            print("Found changes in the event cache.")
            eventCache = newEventCache
            cacheSummaryHash = hashString
            stale = false
            
            
            DispatchQueue.main.async { self.objectWillChange.send() }
        } else {
            
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
        return changes
    }
    
    deinit {
        eventStoreSubscription?.cancel()
        calendarPrefsSubscription?.cancel()
        hiddenEventManagerSubscription?.cancel()
        logger.debug("EventCache deinitialized")
    }
}
