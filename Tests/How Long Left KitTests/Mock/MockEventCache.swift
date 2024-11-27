//
//  MockEventCache.swift
//  How Long Left Tests
//
//  Created by Ryan on 23/11/2024.
//

import Foundation
@testable import HowLongLeftKit

public final class MockEventCache: EventCache {
    // Store mock events
    private var mockEvents: [Event] = []
    private var mockHash: String?
    
    public override init(calendarReader: CalendarSource? = nil,
                         calendarProvider: any EventFilteringOptionsProvider = MockEventFilteringOptionsProvider(),
                         calendarContexts: Set<String> = [],
                         hiddenEventManager: StoredEventManager = MockHiddenEventManager(),
                         id: String = "mockCache",
                         updatesCache: Bool = false) {
        super.init(calendarReader: calendarReader,
                   calendarProvider: calendarProvider,
                   calendarContexts: calendarContexts,
                   hiddenEventManager: hiddenEventManager,
                   id: id,
                   updatesCache: updatesCache)
    }
    
    /// Set mock events
    public func setMockEvents(_ events: [Event]) {
        self.mockEvents = events
        self.mockHash = calculateHash(for: events.map { $0.startDate })
    }
    
    /// Get events
    public override func getEvents() async -> [Event] {
        return mockEvents
    }
    
    /// Update events (does nothing in mock)
    public func updateEvents() {
        // Do nothing; mock behaviour only
    }
    
   
}
