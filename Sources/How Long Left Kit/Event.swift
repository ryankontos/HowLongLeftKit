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
    public var id: String
    
    init(event: EKEvent) {
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.id = event.id
        self.calId = event.calendar?.calendarIdentifier ?? "Nil"
    }
    
    public init(title: String, start: Date, end: Date) {
        self.title = title
        self.startDate = start
        self.endDate = end
        self.id = title
        self.calId = "none"
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



