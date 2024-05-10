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
        let start = Date()
        var timePoints = [TimePoint]()
        var dates = [Date()]
        dates.append(contentsOf: events.flatMap { [$0.startDate, $0.endDate] }.sorted())

        for date in dates {
            if date >= now {
                timePoints.append(generateTimePoint(for: date, from: events))
            }
        }
        
        print("Generated time points in \(Date().timeIntervalSince(start))")
        
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
        
        return TimePoint(date: date, inProgressEvents: currentArray, upcomingEvents: upcomingArray)
        
    }
    
}

