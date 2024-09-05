//
//  CalendarReader.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
@preconcurrency import EventKit

public class CalendarSource: ObservableObject {
    
    internal let eventStore = EKEventStore()
    
    public var authorization: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    private var updateStreamContinuation: AsyncStream<Void>.Continuation?
    public lazy var updateStream: AsyncStream<Void> = {
        AsyncStream { continuation in
            updateStreamContinuation = continuation
        }
    }()
    
    public init(requestCalendarAccessImmediately request: Bool) {
        if request {
            Task {
                
            }
        }
    }
    
    func setup() async {
         let _ = await requestCalendarAccess()
    }
    
    func requestCalendarAccess() async -> Bool {
        
        var optionalResult: Bool?
        
        if #available(macOS 14.0, *) {
             optionalResult = try? await eventStore.requestFullAccessToEvents()
        } else {
            optionalResult = try? await eventStore.requestAccess(to: .event)
        }
        let result = optionalResult ?? false
       
      
        
        return result
    }
    
    func getEvents(from calendars: [EKCalendar]) -> [EKEvent] {
        
        
        
        if calendars.isEmpty {
            return []
        }
        
        //print("Get events from \(calendars.count) calendars")
        
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let end = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        
        let request = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: request)
        
        print("Get events returning \(events.count) events")
        
        return events
        
    }
    
    public func lookupCalendar(withID id: String) -> EKCalendar? {
        guard let cal = eventStore.calendar(withIdentifier: id) else { return nil }
        return cal
    }
    
}


public struct HLLCalendar: Sendable {
    
    var title: String
    
    init(ekCalendar: EKCalendar) {
        self.title = ekCalendar.title
    }
    
}
