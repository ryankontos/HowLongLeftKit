//
//  TimePointGenerator.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

class TimePointGenerator {

    init() {}

    func generateFirstPoint(for events: [HLLEvent], withCacheSummaryHash hash: String) -> TimePoint {
        return generateTimePoint(for: Date(), from: events, withCacheSummaryHash: hash)
    }

    func generateTimePoints(for events: [HLLEvent], withCacheSummaryHash hash: String) -> [TimePoint] {
        let now = Date()
        var timePoints = [TimePoint]()
        var dates = [Date()]
        dates.append(contentsOf: events.flatMap { [$0.startDate, $0.endDate] }.sorted())

        for date in dates {
            if date >= now {
                timePoints.append(generateTimePoint(for: date, from: events, withCacheSummaryHash: hash))
            }
        }
        
        timePoints.sort { $0.date < $1.date }
        
        return timePoints
    }

    func generateTimePoint(for date: Date, from events: [HLLEvent], withCacheSummaryHash hash: String) -> TimePoint {
        var currentArray = [HLLEvent]()
        var upcomingArray = [HLLEvent]()
        
        for event in events {
            if event.status(at: date) == .inProgress {
                currentArray.append(event)
            } else if event.status(at: date) == .upcoming {
                upcomingArray.append(event)
            }
        }
        
        currentArray = currentArray.sortedByEndDate()
        upcomingArray = upcomingArray.sortedByStartDate()
        
        return TimePoint(date: date, cacheSummaryHash: hash, inProgressEvents: currentArray, upcomingEvents: upcomingArray)
    }

    func generateCalendarGroups(for events: [HLLEvent], withCacheSummaryHash hash: String) -> [CalendarGroup] {
        // Group events by calendar ID
        let eventsByCalendar = Dictionary(grouping: events, by: { $0.calendarID })
        
        var calendarGroups = [CalendarGroup]()
        
        // For each calendar ID group
        for (_, calendarEvents) in eventsByCalendar {
            // Get the unique calendar
            guard let calendarID = calendarEvents.first?.calendarID else { continue }
            
            // Generate time points for the events in this calendar
            let timePoints = generateTimePoints(for: calendarEvents, withCacheSummaryHash: hash)
            
            // Create the CalendarGroup and add it to the array
            let calendarGroup = CalendarGroup(calendarID: calendarID, timePoints: timePoints)
            calendarGroups.append(calendarGroup)
        }
        
        return calendarGroups
    }
}
