//
//  TimePointStore.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import Combine
import os.log


public class TimePointStore: ObservableObject {
    
    private let pointGen = TimePointGenerator(groupingMode: .countdownDate)
    
    var points: [TimePoint]?
    private var updateTimer: Timer?
    
    public var currentPoint: TimePoint? {
        return getPointAt(date: Date())
    }
    
    let eventCache: EventCache
    
    public init(eventCache: EventCache) {
       
        self.eventCache = eventCache
        
        
    }
    
    public func setup() async {
        await updatePoints()
    }
    
    
    public func getPointAt(date: Date) -> TimePoint? {
        let point = points?.last(where: { $0.date < date })
        if point == nil { return points?.first }
        return point
    }
    
    private func updatePoints() async {
        let oldpoints = points
        var newResult = [TimePoint]()
        var foundChanges = true
        let events = await eventCache.getEvents()
        
        let newPoints = pointGen.generateTimePoints(for: events)
        
       
            self.points = newPoints
    
        
     
        
        
      
    }
    
   /* private func scheduleNextUpdate() {
        updateTimer?.invalidate()
        let now = Date()
        if let nextUpdateTime = points?.first(where: { $0.date > now })?.date {
            if nextUpdateTime > now {
                let timeInterval = nextUpdateTime.timeIntervalSince(now)
                updateTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(handleTimerFired), userInfo: nil, repeats: false)
                RunLoop.main.add(updateTimer!, forMode: .common)
            }
        }
    } */
    
 
    
 
}
