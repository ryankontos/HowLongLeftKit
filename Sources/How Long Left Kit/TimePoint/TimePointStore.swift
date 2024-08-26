//
//  TimePointStore.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import Combine
import os.log

@MainActor
public class TimePointStore: EventCacheObserver, ObservableObject {
    
    private let pointGen = TimePointGenerator(groupingMode: .countdownDate)
    
    var points: [TimePoint]?
    private var updateTimer: Timer?
    
    public var currentPoint: TimePoint? {
        return getPointAt(date: Date())
    }
    
    override public init(eventCache: EventCache) {
        super.init(eventCache: eventCache)
        
        Task {
            await updatePoints()
        }
    }
    
    
    
    public func getPointAt(date: Date) -> TimePoint? {
        let point = points?.last(where: { $0.date < date })
        if point == nil { return points?.first }
        return point
    }
    
    private func updatePoints() async {
        let oldpoints = points
        var newResult = [TimePoint]()
        var foundChanges = false
        let events = await eventCache.getEvents()
        
        let newPoints = pointGen.generateTimePoints(for: events)
        
        for point in newPoints {
            if let oldMatch = points?.first(where: { $0.date == point.date }) {
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
            if nextUpdateTime > now {
                let timeInterval = nextUpdateTime.timeIntervalSince(now)
                updateTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(handleTimerFired), userInfo: nil, repeats: false)
                RunLoop.main.add(updateTimer!, forMode: .common)
            }
        }
    }
    
    @objc private func handleTimerFired() {
        Task {
            await updatePoints()
        }
    }
    
    public override func eventsChanged() {
        Task {
            await updatePoints()
        }
    }
}
