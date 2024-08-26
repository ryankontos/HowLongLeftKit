//
//  TimePointGenerator.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

@MainActor
class TimePointGenerator {
    
    private var groupMode: GroupMode
    private var includeMultiDayEvents: Bool
    
    init(groupingMode: GroupMode, includeMultiDayEvents: Bool = true) {
        self.groupMode = groupingMode
        self.includeMultiDayEvents = includeMultiDayEvents
    }
    
    func generateFirstPoint(for events: [Event]) -> TimePoint {
        
       
        return generateTimePoint(for: Date(), from: events)
        
    }
    
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
       
        currentArray = currentArray.sortedByEndDate()
        upcomingArray = upcomingArray.sortedByStartDate()
        
        let grouped = groupEventsByDate(events, at: date, by: .countdownDate)
        let upcomingGroup = groupEventsByDate(upcomingArray, at: date, by: .start)
        
        return TimePoint(date: date, inProgressEvents: currentArray, upcomingEvents: upcomingArray, allGroupedByCountdownDate: grouped, upcomingGroupedByStart: upcomingGroup)
    }
    
    private func groupEventsByDate(_ events: [Event], at date: Date = Date(), by: GroupMode) -> [EventDate] {
        var eventDictionary = [Date: [Event]]()
        
        for event in events {
            var groupUsing: Date
            
            switch by {
            case .start:
                groupUsing = event.startDate
            case .countdownDate:
                groupUsing = event.countdownDate(at: date)
            }
            
            if includeMultiDayEvents {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: groupUsing)
                let endOfDay = calendar.startOfDay(for: event.endDate)
                var currentDate = startOfDay
                
                while currentDate <= endOfDay {
                    if eventDictionary[currentDate] != nil {
                        eventDictionary[currentDate]?.append(event)
                    } else {
                        eventDictionary[currentDate] = [event]
                    }
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
            } else {
                let startOfDay = Calendar.current.startOfDay(for: groupUsing)
                if eventDictionary[startOfDay] != nil {
                    eventDictionary[startOfDay]?.append(event)
                } else {
                    eventDictionary[startOfDay] = [event]
                }
            }
        }
        
        let eventDates = eventDictionary.map { EventDate(date: $0.key, events: $0.value) }
        
        return eventDates.sorted { $0.date < $1.date }
    }
    
    enum GroupMode {
        case start
        case countdownDate
    }
    
}
