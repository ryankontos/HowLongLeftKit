//
//  TimePointGenerator.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

class TimePointGenerator {
    
    func generateTimePoints(for events: [Event]) -> [TimePoint] {
        let now = Date()
       
        var timePoints = [TimePoint]()
        var dates = [Date()]
        dates.append(contentsOf: events.flatMap { [$0.startDate, $0.endDate] }.sorted())

        for date in dates {
            if date >= now {
                timePoints.append(generateTimePoint(for: date, from: events))
            }
        }
        
        return timePoints
    }
    
    func generateTimePoint(for date: Date, from events: [Event]) -> TimePoint {
        var currentArray = [Event]()
        var upcomingArray = [Event]()
        
        for event in events {
            if event.status(at: date) == .inProgress {
                currentArray.append(event)
            } else if event.status(at: date) == .upcoming {
                upcomingArray.append(event)
            }
        }
       
        let upcomingGrouped = groupEventsByDate(upcomingArray)
        
        return TimePoint(date: date, inProgressEvents: currentArray, upcomingEvents: upcomingArray, upcomingGrouped: upcomingGrouped)
    }
    
    private func groupEventsByDate(_ events: [Event]) -> [EventDate] {
        var eventDictionary = [Date: [Event]]()
        
        for event in events {
            let startOfDay = Calendar.current.startOfDay(for: event.startDate)
            if eventDictionary[startOfDay] != nil {
                eventDictionary[startOfDay]?.append(event)
            } else {
                eventDictionary[startOfDay] = [event]
            }
        }
        
        let eventDates = eventDictionary.map { EventDate(date: $0.key, events: $0.value) }
        
        return eventDates.sorted { $0.date < $1.date }
    }
}
