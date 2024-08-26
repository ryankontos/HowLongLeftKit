//
//  EventProgressManager.swift
//
//
//  Created by Ryan on 18/6/2024.
//

import Foundation
import Combine

@MainActor
public class EventProgressManager: ObservableObject {
    @Published public var progress: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    
    private let event: Event
    
    public init(event: Event) {
        self.event = event
        updateProgress()
        start()
    }
    
    private func start() {
        let defaultPublisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().map { _ in () }.eraseToAnyPublisher()
        
        defaultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProgress()
            }
            .store(in: &cancellables)
    }
    
    private func updateProgress() {
        let now = Date()
        guard now >= event.startDate else {
            self.progress = 0.0
            return
        }
        guard now <= event.endDate else {
            self.progress = 1.0
            return
        }
        
        let totalDuration = event.endDate.timeIntervalSince(event.startDate)
        let elapsed = now.timeIntervalSince(event.startDate)
        self.progress = elapsed / totalDuration
    }
}
