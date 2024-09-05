//
//  TimePoint.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

public struct TimePoint: Equatable, Identifiable, Sendable {
    
    public var date: Date
    
    public var inProgressEvents: [Event]
    public var upcomingEvents: [Event]
    
    public var allEvents: [Event] {
        return inProgressEvents + upcomingEvents
    }
    
    public var allGroupedByCountdownDate: [EventDate]
    public var upcomingGroupedByStart: [EventDate]
    
    nonisolated public let id: Date
    
    public init(date: Date, inProgressEvents: [Event], upcomingEvents: [Event], allGroupedByCountdownDate: [EventDate], upcomingGroupedByStart: [EventDate]) {
        self.date = date
        self.inProgressEvents = inProgressEvents
        self.upcomingEvents = upcomingEvents
        self.allGroupedByCountdownDate = allGroupedByCountdownDate
        self.upcomingGroupedByStart = upcomingGroupedByStart
        self.id = date
    }
    
    nonisolated public static func == (lhs: TimePoint, rhs: TimePoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func fetchSingleEvent(accordingTo rule: SingleEventFetchRule) -> Event? {
        switch rule {
        case .upcomingOnly:
            return upcomingEvents.first

        case .inProgressOnly:
            return inProgressEvents.first

        case .preferUpcoming:
            return upcomingEvents.first ?? inProgressEvents.first

        case .preferInProgress:
            return inProgressEvents.first ?? upcomingEvents.first

        case .soonestCountdownDate:
            let nextUpcomingEvent = upcomingEvents.first
            let nextInProgressEvent = inProgressEvents.first
            
            if let nextUpcomingEvent = nextUpcomingEvent, let nextInProgressEvent = nextInProgressEvent {
                return nextUpcomingEvent.countdownDate(at: date) < nextInProgressEvent.countdownDate(at: date) ? nextUpcomingEvent : nextInProgressEvent
            }
            
            return nextUpcomingEvent ?? nextInProgressEvent
            
           // Finish implementing
            
        case .noEvents:
            return nil
        }
    }
    
    
  

}

public enum SingleEventFetchRule: Int {
    
    case upcomingOnly = 0 // Return only the next to start event
    case inProgressOnly = 1 // Return only the next event to end, that is currently in progress
    case preferUpcoming = 2 // Return the next event to start. If there is not one, return the next in progress event to end
    case preferInProgress = 3 // Return the next in progress event to end, if there is not one, return the next upcoming event to start
    case soonestCountdownDate = 4 // Return either an in progress or an upcoming event, whichever is closest to either starting or ending (if it is in progress)
    case noEvents = 5
}
