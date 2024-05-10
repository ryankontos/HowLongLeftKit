//
//  EventManagerObserver.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import Combine

public class EventCacheObserver {
    
    let eventCache: EventCache
    
    private var eventSubscription: AnyCancellable?
    
    public init(eventCache: EventCache) {
        self.eventCache = eventCache
        observeEventChanges()
    }
    
    internal func eventsChanged() { }
    
    private final func observeEventChanges() {
        eventSubscription = eventCache.objectWillChange
            .sink(receiveValue: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.eventsChanged()
                }
            })
       }
       
    deinit {
        eventSubscription?.cancel()
    }
    
}
