//
//  HLLEvent.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit

#if canImport(SwiftUI)
import SwiftUI
#endif

public class HLLEvent: ObservableObject, Identifiable, Hashable, Equatable {
    
    @Published public var title: String
    @Published public var startDate: Date
    @Published public var endDate: Date
       
    @Published public var calendar: HLLCalendar
    
    public var calendarID: String {
        return calendar.calendarIdentifier
    }
    
    @Published public var isAllDay: Bool
    
    @Published public var structuredLocation: EKStructuredLocation?
    
    @Published internal(set) public var isPinned: Bool = false
    
    public var locationName: String? {
        if let locationName = structuredLocation?.title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !locationName.isEmpty, locationName.rangeOfCharacter(from: .alphanumerics) != nil {
            return locationName
        }
        return nil

        
    }
    
    public var location: CLLocation? {
        return structuredLocation?.geoLocation
    }
    
    public var eventIdentifier: String
    
    public var id: String
    
    public func completion(at date: Date = Date()) -> Double {
            guard startDate <= date, endDate > date else {
                return startDate > date ? 0.0 : 1.0
            }
            let totalDuration = endDate.timeIntervalSince(startDate)
            let elapsedDuration = date.timeIntervalSince(startDate)
            return max(0.0, min(1.0, elapsedDuration / totalDuration))
    }
    
    init(event: EKEvent) {
        self.title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.id = event.id
        self.eventIdentifier = event.eventIdentifier
        self.calendar = HLLCalendar(ekCalendar: event.calendar)
        self.isAllDay = event.isAllDay
        self.structuredLocation = event.structuredLocation
    }
    
    public init(title: String, start: Date, end: Date, location: String? = nil, isAllDay: Bool = false, calendar: HLLCalendar) {
        self.title = title
        self.startDate = start
        self.endDate = end
        self.id = title
        self.calendar = calendar
        self.isAllDay = isAllDay
        self.isPinned = false
        
        self.eventIdentifier = UUID().uuidString
    }
    
    public func countdownDate(at date: Date = Date()) -> Date {
        if status(at: date) == .upcoming {
            return startDate
        } else {
            return endDate
        }
    }
    
    public func status(at date: Date = Date()) -> Status {
        let currentDate = date

        if currentDate < startDate {
            return .upcoming
        } else if currentDate >= startDate && currentDate < endDate {
            return .inProgress
        } else {
            return .ended
        }
    }

    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: HLLEvent, rhs: HLLEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    public enum Status {
        case ended
        case inProgress
        case upcoming
    }
    
    public static func makeExampleEvent(title: String, start: Date = .now, end: Date) -> HLLEvent {
        return HLLEvent(title: title, start: start, end: end, calendar: HLLCalendar(calendarIdentifier: UUID().uuidString, title: "Calendar", color: .cyan))
    }
        
    
    public static var example: HLLEvent {
        return HLLEvent(title: "Example Event", start: Date(), end: Date().addingTimeInterval(3500), calendar: HLLCalendar(calendarIdentifier: UUID().uuidString, title: "Calendar", color: .pink))
    }
    
    #if canImport(SwiftUI)
    
    internal func setColor(color: Color) {
        self.color = color
    }
    
    public private(set) var color: Color = .blue
    
    #endif
    
}


public extension Array where Element == HLLEvent {
    
    // Function to sort by start date
    func sortedByStartDate() -> [HLLEvent] {
        return self.sorted { $0.startDate < $1.startDate }
    }
    
    // Function to sort by end date
    func sortedByEndDate() -> [HLLEvent] {
        return self.sorted { $0.endDate < $1.endDate }
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

