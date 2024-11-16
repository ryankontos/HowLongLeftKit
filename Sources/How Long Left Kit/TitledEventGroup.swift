//
//  TitledEventGroup.swift
//
//
//  Created by Ryan on 25/5/2024.
//

import Foundation

public class TitledEventGroup: Identifiable {
    
    public init(_ title: String?, _ info: String?, _ events: [Event]) {
        self.title = title
        self.events = events.filter({ $0.isAllDay == false })
        self.allDayEvents = events.filter({ $0.isAllDay == true })
        self.info = info
        self.combinedEvents = events
    }
    
    public var title: String?
    public var info: String?
    
    public var combinedEvents: [Event] // All events
    
    public var allDayEvents: [Event] // All day events
    public var events: [Event] // Non all day events
    
    public var flags = [Flags]()
    
    static public func makeGroup(title: String?, info: String?, events: [Event], makeIfEmpty: Bool) -> TitledEventGroup? {
        
        if events.isEmpty, makeIfEmpty == false {
            return nil
        }
        
        return TitledEventGroup(title, info, events)
    }
    
    public enum Flags {
        
        case headerSection
        case prominentSection
        
    }
    
}
