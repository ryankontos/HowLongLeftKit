//
//  TimePoint.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import AppIntents

public class TimePoint: Equatable, ObservableObject, Identifiable {
    
    public var date: Date
    
    public var cacheSummaryHash: String
    
    @Published public var inProgressEvents: [Event]
    @Published public var upcomingEvents: [Event]
    
    public var allEvents: [Event] {
        return inProgressEvents + upcomingEvents
    }
    
    @Published public var allGroupedByCountdownDate: [EventDate]
    @Published public var upcomingGroupedByStart: [EventDate]
    
    public var id: Date { return date }
    
    public init(date: Date, cacheSummaryHash: String, inProgressEvents: [Event], upcomingEvents: [Event], allGroupedByCountdownDate: [EventDate], upcomingGroupedByStart: [EventDate]) {
        self.date = date
        self.cacheSummaryHash = cacheSummaryHash
        self.inProgressEvents = inProgressEvents.filter { $0.status(at: date) == .inProgress }
        self.upcomingEvents = upcomingEvents.filter { $0.status(at: date) == .upcoming }
        self.allGroupedByCountdownDate = allGroupedByCountdownDate
        self.upcomingGroupedByStart = upcomingGroupedByStart

        // Check that inProgressEvents only contain in-progress events
        for event in self.inProgressEvents {
            if event.status(at: date) != .inProgress {
                fatalError("Event \(event.title) is not in progress at \(date)")
            }
        }

        // Check that upcomingEvents only contain upcoming events
        for event in self.upcomingEvents {
            if event.status(at: date) != .upcoming {
                fatalError("Event \(event.title) is not upcoming at \(date)")
            }
        }
    }
    
    public static func == (lhs: TimePoint, rhs: TimePoint) -> Bool {
        return lhs.date == rhs.date && lhs.inProgressEvents == rhs.inProgressEvents && lhs.upcomingEvents == rhs.upcomingEvents
    }
    
    public func fetchSingleEvent(accordingTo rule: EventFetchRule) -> Event? {
        // Use the new fetchEvents method to get the filtered and sorted array of events
        let filteredEvents = fetchEvents(accordingTo: rule)
        
        // Return the first event in the filtered list, or nil if the list is empty
        return filteredEvents.first
    }
    
    public func fetchEvents(accordingTo rule: EventFetchRule) -> [Event] {
        var filteredEvents: [Event]
        
        switch rule {
        case .upcomingOnly:
            filteredEvents = upcomingEvents.sortedByStartDate() // Only upcoming events, sorted by start date
            
        case .inProgressOnly:
            filteredEvents = inProgressEvents.sortedByStartDate() // Only in-progress events, sorted by start date
            
        case .preferUpcoming:
            // Combine both upcoming and in-progress events, prioritizing upcoming ones
            filteredEvents = upcomingEvents.sortedByStartDate() + inProgressEvents.sortedByStartDate()
            
        case .preferInProgress:
            // Combine both in-progress and upcoming events, prioritizing in-progress ones
            filteredEvents = inProgressEvents.sortedByStartDate() + upcomingEvents.sortedByStartDate()
            
        case .soonestCountdownDate:
            // Combine both upcoming and in-progress events and sort by their countdown date
            filteredEvents = allEvents.sorted {
                $0.countdownDate(at: date) < $1.countdownDate(at: date)
            }
        case .noEvents:
            filteredEvents = []
        }
        
        return filteredEvents
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

public enum EventFetchRule: Int, CaseIterable {
    
    case noEvents
    case upcomingOnly
    case inProgressOnly
    case preferUpcoming
    case preferInProgress
    case soonestCountdownDate
    
}

