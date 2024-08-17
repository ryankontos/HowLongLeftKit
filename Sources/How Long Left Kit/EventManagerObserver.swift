//
//  EventManagerObserver.swift
//  How Long Left
//
//  Created by Ryan on 2/5/2024.
//

import Foundation
import Combine

@MainActor
open class EventCacheObserver {
    
    let eventCache: EventCache
    
    private var eventSubscription: AnyCancellable?
    private let queue = DispatchQueue(label: "com.howlongleft.EventCacheObserver", attributes: .concurrent)
    
    public init(eventCache: EventCache) {
        self.eventCache = eventCache
        observeEventChanges()
    }
    
    open func eventsChanged() { }
    
    private final func observeEventChanges() {
        eventSubscription = eventCache.objectWillChange
            .receive(on: queue)
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

