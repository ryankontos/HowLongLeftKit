//
//  TimePoint.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

public class TimePoint: Equatable, ObservableObject, Identifiable {
    
    public var date: Date
    
    @Published public var inProgressEvents: [Event]
    @Published public var upcomingEvents: [Event]
    
    public var allEvents: [Event] {
        return inProgressEvents + upcomingEvents
    }
    
    @Published public var allGroupedByCountdownDate: [EventDate]
    @Published public var upcomingGroupedByStart: [EventDate]
    
    public var id: Date { return date }
    
    public init(date: Date, inProgressEvents: [Event], upcomingEvents: [Event], allGroupedByCountdownDate: [EventDate], upcomingGroupedByStart: [EventDate]) {
        self.date = date
        self.inProgressEvents = inProgressEvents
        self.upcomingEvents = upcomingEvents
        self.allGroupedByCountdownDate = allGroupedByCountdownDate
        self.upcomingGroupedByStart = upcomingGroupedByStart
    }
    
    public static func == (lhs: TimePoint, rhs: TimePoint) -> Bool {
        return lhs.date == rhs.date && lhs.inProgressEvents == rhs.inProgressEvents && lhs.upcomingEvents == rhs.upcomingEvents
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
    
    
    func updateInfo(from new: TimePoint) -> Bool {
        var flag = false
        updateIfNeeded(&self.inProgressEvents, compareTo: new.inProgressEvents, flag: &flag)
        updateIfNeeded(&self.upcomingEvents, compareTo: new.upcomingEvents, flag: &flag)
        updateIfNeeded(&self.allGroupedByCountdownDate, compareTo: new.allGroupedByCountdownDate, flag: &flag)
        updateIfNeeded(&self.upcomingGroupedByStart, compareTo: new.upcomingGroupedByStart, flag: &flag)
        return flag
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
