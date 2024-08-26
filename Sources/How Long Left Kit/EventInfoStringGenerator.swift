//
//  File.swift
//  
//
//  Created by Ryan on 18/6/2024.
//

import Foundation

@MainActor
public protocol EventInfoStringGenerator {
    
    func getString(from event: Event, at date: Date) -> String
    
}

@MainActor
public class EventCountdownTextGenerator: EventInfoStringGenerator {
    
    public init() {
        
    }
    
    public func getString(from event: Event, at date: Date) -> String {
        let status = event.status(at: date)
        switch status {
        case .ended:
            return "Ended"
        case .inProgress:
            return "\(formatTimeInterval(to: event.endDate)) remaining"
        case .upcoming:
            return "in \(formatTimeInterval(to: event.startDate))"
        }
    }
    
    private func formatTimeInterval(to futureDate: Date) -> String {
        let currentDate = Date()
        let interval = futureDate.timeIntervalSince(currentDate)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: interval) ?? ""
    }
}
