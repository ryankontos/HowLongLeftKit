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
    
    public var id: Date { return date }
    
    public init(date: Date, inProgressEvents: [Event], upcomingEvents: [Event]) {
        self.date = date
        self.inProgressEvents = inProgressEvents // These are sorted by end date in ascending order
        self.upcomingEvents = upcomingEvents // These are sorted by start date in ascending order
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
            
            if let upcoming = nextUpcomingEvent, let inProgress = nextInProgressEvent {
                let upcomingStartDistance = upcoming.startDate.distance(to: date)
                let inProgressEndDistance = date.distance(to: inProgress.endDate)
                return upcomingStartDistance < inProgressEndDistance ? upcoming : inProgress
            } else {
                return nextUpcomingEvent ?? nextInProgressEvent
            }
        }
    }

}

public enum SingleEventFetchRule {
    
    case upcomingOnly // Return only the next to start event
    case inProgressOnly // Return only the next event to end, that is currently in progress
    case preferUpcoming // Return the next event to start. If there is not one, return the next in progress event to end
    case preferInProgress // Return the next in progress event to end, if there is not one, return the next upcoming event to start
    case soonestCountdownDate // Return either an in progress or an upcoming event, whichever is closest to either starting or ending (if it is in progress)
    
}
