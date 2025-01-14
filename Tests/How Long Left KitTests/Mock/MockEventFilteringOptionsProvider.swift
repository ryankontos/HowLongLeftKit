//
//  MockEventFilteringOptionsProvider.swift
//  HowLongLeftKit
//
//  Created by Ryan on 23/11/2024.
//

import Foundation
@testable import HowLongLeftKit
import EventKit

public final class MockEventFilteringOptionsProvider: CalendarSettingsProvider {
    
    public init() {
        
    }
    
    public func getAllowedCalendars(matchingContextIn contexts: Set<String>) -> [EKCalendar] {
        return []
    }
    
    public func getAllDayAllowed() -> Bool {
        return true
    }
    
    public func updateForNewCals() {
        // No-op for mock
    }
}
