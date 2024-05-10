//
//  File.swift
//  
//
//  Created by Ryan on 7/5/2024.
//

import Foundation
import Defaults
import EventKit

extension Defaults.Keys {
    
    // MARK: - General
    static public let showAllDayEvents = Defaults.Key<Bool>("HLL_showAllDayEvents", default: true)
    
    
    // MARK: - Calendars
    static public let calendarInfos = Defaults.Key<[CalendarInfo]>("HLL_calendarInfos", default: [])
    static public let includeNewCalendars = Defaults.Key<Bool>("HLL_includeNewCalendars", default: true)
    
    
    
}
