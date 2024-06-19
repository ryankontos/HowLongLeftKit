//
//  DefaultContainer.swift
//  How Long Left
//
//  Created by Ryan on 10/5/2024.
//

import Foundation

open class DefaultContainer {
    
    public let calendarReader: CalendarSource
    public let calendarPrefsManager: EventFilterDefaultsManager
    public let eventCache: EventCache
    public let pointStore: TimePointStore
    
    public let timerContainer = GlobalTimerContainer()
    
    public init() {
        
        calendarReader = CalendarSource(requestCalendarAccessImmediately: true)
        
        let appSet: Set<String> = [HLLStandardCalendarContexts.app.rawValue]
        let config = EventFilterDefaultsManager.Configuration(domain: "app", defaultContextsForNonMatches: appSet)
        calendarPrefsManager = EventFilterDefaultsManager(calendarSource: calendarReader, config: config)
        
        eventCache = EventCache(calendarReader: calendarReader, calendarProvider: calendarPrefsManager, calendarContexts: [HLLStandardCalendarContexts.app.rawValue])
        pointStore = TimePointStore(eventCache: eventCache)
        
        
    }
    
}
