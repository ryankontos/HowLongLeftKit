//
//  DefaultContainer.swift
//  How Long Left
//
//  Created by Ryan on 10/5/2024.
//

import Foundation

open class DefaultContainer: ObservableObject {
    
    public let calendarReader: CalendarSource
    public let calendarPrefsManager: EventFetchSettingsManager
    public let eventCache: EventCache
    public let pointStore: TimePointStore
    
    public let storedEventManager: StoredEventManager
    
    public let timerContainer = GlobalTimerContainer()
    
    public init() {
        
        let domainString = "app"
        
        calendarReader = CalendarSource(requestCalendarAccessImmediately: true)
        
        let appSet: Set<String> = [HLLStandardCalendarContexts.app.rawValue]
        let config = EventFetchSettingsManager.Configuration(domain: domainString, defaultContextsForNonMatches: appSet)
        calendarPrefsManager = EventFetchSettingsManager(calendarSource: calendarReader, config: config)
        
        storedEventManager = StoredEventManager(domain: domainString)
        
        eventCache = EventCache(calendarReader: calendarReader, calendarProvider: calendarPrefsManager, calendarContexts: [HLLStandardCalendarContexts.app.rawValue], storedEventManager: storedEventManager)
        pointStore = TimePointStore(eventCache: eventCache)
        
        
    }
    
}
