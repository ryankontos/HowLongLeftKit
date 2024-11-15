//
//  HLLCoreServicesContainer.swift
//  How Long Left
//
//  Created by Ryan on 10/5/2024.
//

import Foundation

open class HLLCoreServicesContainer: ObservableObject {
    
    public let calendarReader: CalendarSource
    public let calendarPrefsManager: EventFetchSettingsManager
    public let eventCache: EventCache
    public let pointStore: TimePointStore
    
    public let hiddenEventManager: StoredEventManager
    
    public let selectedEventManager: StoredEventManager
    
    public let timerContainer = GlobalTimerContainer()
    
    public init() {
        
        let domainString = "HowLongLeft_App"
        
        calendarReader = CalendarSource(requestCalendarAccessImmediately: true)
        
        let appSet: Set<String> = [HLLStandardCalendarContexts.app.rawValue]
        let config = EventFetchSettingsManager.Configuration(domain: domainString, defaultContextsForNonMatches: appSet)
        calendarPrefsManager = EventFetchSettingsManager(calendarSource: calendarReader, config: config)
        
        hiddenEventManager = StoredEventManager(domain: "\(domainString)_HiddenEvents")
        
        selectedEventManager = StoredEventManager(domain: "\(domainString)_SelectedEvent", limit: 1)
        
        eventCache = EventCache(calendarReader: calendarReader, calendarProvider: calendarPrefsManager, calendarContexts: [HLLStandardCalendarContexts.app.rawValue], hiddenEventManager: hiddenEventManager, id: "DefaultContainer")
        pointStore = TimePointStore(eventCache: eventCache)
        
        
    }
    
}
