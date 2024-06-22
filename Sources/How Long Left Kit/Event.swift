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
    
    @Published internal(set) public var isHidden: Bool = false
    @Published internal(set) public var isPinned: Bool = false
    
    public var locationName: String? {
        return structuredLocation?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var location: CLLocation? {
        return structuredLocation?.geoLocation
    }
    
    public var eventIdentifier: String
    
    public var id: String
    
    init(event: EKEvent, eventInfo: EventInfo?) {
        self.title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.id = event.id
        self.eventIdentifier = event.eventIdentifier
        self.calId = event.calendar?.calendarIdentifier ?? "Nil"
        self.isAllDay = event.isAllDay
        self.structuredLocation = event.structuredLocation
        
        if let eventInfo = eventInfo {
            self.isHidden = eventInfo.isHidden
            self.isPinned = eventInfo.isPinned
        }
        
    }
    
    public init(title: String, start: Date, end: Date, isAllDay: Bool = false) {
        self.title = title
        self.startDate = start
        self.endDate = end
        self.id = title
        self.calId = "none"
        self.isAllDay = isAllDay
        self.isHidden = false
        self.isPinned = false
        self.eventIdentifier = "none"
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



