//
//  TimePointStore.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import Combine

public class TimePointStore: EventCacheObserver, ObservableObject {
    
    private let pointGen = TimePointGenerator()
    
    var points: [TimePoint]?
    var updateTimer: Timer?
    
    override public init(eventCache: EventCache) {
        super.init(eventCache: eventCache)
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    public func getPointAt(date: Date) -> TimePoint? {
        return points?.last(where: { $0.date < date })
    }
    
    private func updatePoints() {
        
        print("Updating points")
        
        let oldpoints = points
        var newResult = [TimePoint]()
        var foundChanges = false
        let events = eventCache.getEvents()
        
        print("Updating points got \(events.count)")
        
        let newPoints = pointGen.generateTimePoints(for: events)
        
        for point in newPoints {
            if var oldMatch = points?.first(where: { $0.date == point.date }) {
                let changes = updateTimePoint(timePoint: &oldMatch, from: point)
                if changes { foundChanges = true }
                newResult.append(oldMatch)
            } else {
                foundChanges = true
                newResult.append(point)
            }
        }
        
        if newResult != oldpoints { foundChanges = true }
        
        if foundChanges {
            DispatchQueue.main.async {
                self.points = newResult
                self.objectWillChange.send()
                self.scheduleNextUpdate()
            }
        }
    }
    
    private func scheduleNextUpdate() {
        updateTimer?.invalidate()
        let now = Date.now
        if let nextUpdateTime = points?.first(where: { $0.date > now })?.date {
            let now = Date()
            if nextUpdateTime > now {
                updateTimer = Timer.scheduledTimer(withTimeInterval: nextUpdateTime.timeIntervalSince(now), repeats: false) { [weak self] _ in
                    self?.updatePoints()
                }
            }
        }
    }
    
    private func updateTimePoint(timePoint: inout TimePoint, from: TimePoint) -> Bool {
        var flag = false
        updateIfNeeded(&timePoint.inProgressEvents, compareTo: from.inProgressEvents, flag: &flag)
        updateIfNeeded(&timePoint.upcomingEvents, compareTo: from.upcomingEvents, flag: &flag)
        return flag
        
    }
    
    override func eventsChanged() { updatePoints() }
   
}
