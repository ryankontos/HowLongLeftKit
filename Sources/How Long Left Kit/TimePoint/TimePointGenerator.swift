//
//  TimePointGenerator.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation

class TimePointGenerator {

    
    init() {
        
    }
    
    func generateFirstPoint(for events: [Event], withCacheSummaryHash hash: String) -> TimePoint {
        return generateTimePoint(for: Date(), from: events, withCacheSummaryHash: hash)
    }
    
    func generateTimePoints(for events: [Event], withCacheSummaryHash hash: String) -> [TimePoint] {
        let now = Date()
       
        var timePoints = [TimePoint]()
        var dates = [Date()]
        dates.append(contentsOf: events.flatMap { [$0.startDate, $0.endDate] }.sorted())

        for date in dates {
            if date >= now {
                timePoints.append(generateTimePoint(for: date, from: events, withCacheSummaryHash: hash))
            }
        }
        
        return timePoints
    }
    
    func generateTimePoint(for date: Date, from events: [Event], withCacheSummaryHash hash: String) -> TimePoint {
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
        
        return TimePoint(date: date, cacheSummaryHash: hash, inProgressEvents: currentArray, upcomingEvents: upcomingArray)
    }

   
    
  
}
