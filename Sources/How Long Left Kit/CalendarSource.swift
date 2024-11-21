//
//  CalendarReader.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import EventKit
import CryptoKit

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
    
    @MainActor
    public func requestCalendarAccess() async -> Bool {
        
        var optionalResult: Bool?
        
        if #available(macOS 14.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
             optionalResult = try? await eventStore.requestFullAccessToEvents()
        } else {
            optionalResult = try? await eventStore.requestAccess(to: .event)
        }
        let result = optionalResult ?? false
       
        
            self.objectWillChange.send()
        
        
        return result
    }
    
    func getEvents(from calendars: [EKCalendar]) -> EventFetchResult {

        if calendars.isEmpty {
            return EventFetchResult(events: [], calendars: [])
        }

        let calendar = Calendar.current

        // Get the current date
        let now = Date()

        // Set the start date to midnight two days ago
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -2, to: now)!)

        // Set the end date to the last second of the day 14 days from now
        let endDate = calendar.date(byAdding: .day, value: 14, to: now)!
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!

        // Create the event store request
        let request = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: request)

        // Return the result with start and end
        return EventFetchResult(events: events, calendars: calendars, predicateStart: start, predicateEnd: end)
    }
    
    public func lookupCalendar(withID id: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: id)
    }
    
}


struct EventFetchResult {
    var events: [EKEvent]
    var calendars: [EKCalendar]
    var predicateStart: Date?
    var predicateEnd: Date?

    func getHash() -> String {
            var dataToHash = ""

        
            for event in events {
                 let id = String(event.id)
                    dataToHash += id
            
            }

            // Collect calendar identifiers
            for calendar in calendars {
                dataToHash += calendar.calendarIdentifier
            }

            // Add predicateStart and predicateEnd if they exist
            if let start = predicateStart {
                dataToHash += String(start.timeIntervalSince1970)
            }
            
            if let end = predicateEnd {
                dataToHash += String(end.timeIntervalSince1970)
            }

            // Ensure there is data to hash
            guard !dataToHash.isEmpty else { return "" }
            
            // Create a SHA-256 hash of the combined string
            let hashData = SHA256.hash(data: Data(dataToHash.utf8))

            // Convert the hash to a string
            return hashData.map { String(format: "%02x", $0) }.joined()
        }
    
    
}
