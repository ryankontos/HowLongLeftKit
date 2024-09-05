//
//  EventManagerObserver.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//
/*
import Foundation
@preconcurrency import Combine

open class EventCacheObserver {
    
    let eventCache: EventCache
    
    
    private let queue = DispatchQueue(label: "com.howlongleft.EventCacheObserver", attributes: .concurrent)
    
    public init(eventCache: EventCache) {
        self.eventCache = eventCache
        observeEventChanges()
    }
    
    open func eventsChanged() { }
    
    private final func observeEventChanges() {
        
        Task {
            
            for await _ in await eventCache.eventUpdateStream {
                self.eventsChanged()
            }
            
        }
        
       
    }
    
    
}


*/
