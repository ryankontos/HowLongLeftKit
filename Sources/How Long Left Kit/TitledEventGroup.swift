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
    }
    
    public var title: String?
    public var info: String?
    
    public var allDayEvents: [Event]
    public var events: [Event]
    
    public var flags = [Flags]()
    
    static public func makeGroup(title: String?, info: String?, events: [Event], makeIfEmpty: Bool) -> TitledEventGroup? {
        guard !events.isEmpty || makeIfEmpty else { return nil }
        return TitledEventGroup(title, info, events)
    }
    
    public enum Flags {
        
        case headerSection
        case prominentSection
        
    }
    
}
