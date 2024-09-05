//
//  EventDate.swift
//  How Long Left Kit
//
//  Created by Ryan on 3/6/2024.
//

import Foundation

public struct EventDate: Equatable, Sendable {
    public static func == (lhs: EventDate, rhs: EventDate) -> Bool {
        return lhs.date == rhs.date && lhs.events == rhs.events
    }
    
    
    init(date: Date, events: [Event]) {
        self.date = date
        self.events = events
    }
    
    // Must be midnight/start of day
    public var date: Date
    
    // Events that occur on this day
    public var events: [Event]
    
}
