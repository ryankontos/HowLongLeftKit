//
//  File.swift
//  
//
//  Created by Ryan on 18/6/2024.
//

import Foundation

public protocol EventInfoStringGenerator {
    
    func getString(from event: HLLEvent, at date: Date) -> String
    
}


public class EventCountdownTextGenerator: EventInfoStringGenerator {
    
    var showContext: Bool
    var postional: Bool
    
    public init(showContext: Bool, postional: Bool) {
        self.showContext = showContext
        self.postional = postional
    }
    
    public func getString(from event: HLLEvent, at date: Date) -> String {
        let status = event.status(at: date)
        switch status {
        case .ended:
            return "Ended"
        case .inProgress:
            let timeString = formatTimeInterval(to: event.endDate)
            return showContext ? "\(timeString) remaining" : timeString
        case .upcoming:
            let timeString = formatTimeInterval(to: event.startDate)
            return showContext ? "in \(timeString)" : timeString
        }
    }
    
    private func formatTimeInterval(to futureDate: Date) -> String {
        let currentDate = Date()
        let interval = futureDate.timeIntervalSince(currentDate)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = postional ? .positional : .abbreviated
        
        return formatter.string(from: interval) ?? ""
    }
}
