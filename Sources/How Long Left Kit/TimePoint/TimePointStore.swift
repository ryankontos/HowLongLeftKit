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
    
    public var currentPoint: TimePoint? {
        return getPointAt(date: Date())
    }
    
    override public init(eventCache: EventCache) {
        super.init(eventCache: eventCache)
        updatePoints()
        
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    public func getPointAt(date: Date) -> TimePoint? {
        let p = points?.last(where: { $0.date < date })
        return p
    }
    
    private func updatePoints() {
        
        //print("Updating points")
        
        let oldpoints = points
        var newResult = [TimePoint]()
        var foundChanges = false
        let events = eventCache.getEvents()
        
        //print("Updating points got \(events.count)")
        
        let newPoints = pointGen.generateTimePoints(for: events)
        
        for point in newPoints {
            if var oldMatch = points?.first(where: { $0.date == point.date }) {
                let changes = oldMatch.updateInfo(from: point)
                if changes { foundChanges = true }
                newResult.append(oldMatch)
            } else {
                foundChanges = true
                newResult.append(point)
            }
        }
        
        if newResult != oldpoints { foundChanges = true }
        
        if foundChanges {
            self.points = newResult
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.scheduleNextUpdate()
            }
        }
    }
    
    private func scheduleNextUpdate() {
        updateTimer?.invalidate()
        let now = Date()
        if let nextUpdateTime = points?.first(where: { $0.date > now })?.date {
            let now = Date()
            if nextUpdateTime > now {
                updateTimer = Timer.scheduledTimer(withTimeInterval: nextUpdateTime.timeIntervalSince(now), repeats: false) { [weak self] _ in
                    self?.updatePoints()
                }
            }
        }
    }
    
   
    
    public override func eventsChanged() { updatePoints() }
   
}
