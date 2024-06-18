//
//  Event.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit

public class Event: ObservableObject, Identifiable, Hashable, Equatable {
    
    @Published public var title: String
    @Published public var startDate: Date
    @Published public var endDate: Date
    
    @Published public var calId: String
    
    @Published public var isAllDay: Bool
    
    @Published public var structuredLocation: EKStructuredLocation?
    
    public var locationName: String? {
        return structuredLocation?.title
    }
    
    public var location: CLLocation? {
        return structuredLocation?.geoLocation
    }
    
    public var id: String
    
    init(event: EKEvent) {
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.id = event.id
        self.calId = event.calendar?.calendarIdentifier ?? "Nil"
        self.isAllDay = event.isAllDay
        self.structuredLocation = event.structuredLocation
    }
    
    public init(title: String, start: Date, end: Date, isAllDay: Bool = false) {
        self.title = title
        self.startDate = start
        self.endDate = end
        self.id = title
        self.calId = "none"
        self.isAllDay = isAllDay
    }
    
    public func countdownDate(at date: Date = Date()) -> Date {
        if status(at: date) == .upcoming {
            return startDate
        } else {
            return endDate
        }
    }
    
    public func status(at date: Date = Date()) -> Status {
        
        let endInterval = endDate.timeIntervalSince(date)
        if startDate.timeIntervalSince(date) >= 0 {
            return .upcoming
        } else if endInterval < 1 {
            return .ended
        } else {
            return .inProgress
        }
        
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    
    public enum Status {
        case ended
        case inProgress
        case upcoming
    }
    
}



