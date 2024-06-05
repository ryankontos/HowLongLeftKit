//
//  CalendarReader.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit

public class CalendarSource: ObservableObject {
    
    internal let eventStore = EKEventStore()
    
    public var authorization: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    public init(requestCalendarAccessImmediately request: Bool) {
        if request {
            Task {
                await requestCalendarAccess()
            }
        }
    }
    
    func requestCalendarAccess() async -> Bool {
        
        var optionalResult: Bool?
        
        if #available(macOS 14.0, *) {
             optionalResult = try? await eventStore.requestFullAccessToEvents()
        } else {
            optionalResult = try? await eventStore.requestAccess(to: .event)
        }
        let result = optionalResult ?? false
       
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        return result
    }
    
    func getEvents(from calendars: [EKCalendar]) -> [EKEvent] {
        
        if calendars.isEmpty {
            return []
        }
        
        //print("Get events from \(calendars.count) calendars")
        
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 14, to: start)!
        
        let request = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: request)
        
        //print("Get events returning \(events.count) events")
        
        return events
        
    }
    
    public func lookupCalendar(withID id: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: id)
    }
    
}
