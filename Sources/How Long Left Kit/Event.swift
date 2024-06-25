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
    
    @Published public var calendarID: String
    
    @Published public var isAllDay: Bool
    
    @Published public var structuredLocation: EKStructuredLocation?
    
    @Published internal(set) public var isPinned: Bool = false
    
    public var locationName: String? {
        return structuredLocation?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var location: CLLocation? {
        return structuredLocation?.geoLocation
    }
    
    public var eventID: String
    
    public var id: String
    
    init(event: EKEvent) {
        self.title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.id = event.id
        self.eventID = event.eventIdentifier
        self.calendarID = event.calendar?.calendarIdentifier ?? "Nil"
        self.isAllDay = event.isAllDay
        self.structuredLocation = event.structuredLocation
       
        
    }
    
    public init(title: String, start: Date, end: Date, isAllDay: Bool = false) {
        self.title = title
        self.startDate = start
        self.endDate = end
        self.id = title
        self.calendarID = "none"
        self.isAllDay = isAllDay
        self.isPinned = false
        self.eventID = "none"
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




public protocol EventInfoProtocol {
    
    var title: String { get set }
    var startDate: Date { get set }
    var endDate: Date { get set }
    var isAllDay: Bool { get set }
    var calendarID: String { get set }
    var eventID: String { get set }
    var isHidden: Bool { get }
    var isPinned: Bool { get }
    
}
