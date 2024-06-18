//
//  File.swift
//  
//
//  Created by Ryan on 18/6/2024.
//

import Foundation
import Combine

@MainActor
public class InfoStringManager: ObservableObject {
    @Published public var infoString: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    private var stringGenerator: EventInfoStringGenerator
    private var event: Event
    
    public init(event: Event, stringGenerator: EventInfoStringGenerator, publisher: AnyPublisher<Void, Never>? = nil) {
        
        self.event = event
        self.stringGenerator = stringGenerator
        
        updateInfo()
        
        let defaultPublisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().map { _ in () }.eraseToAnyPublisher()
        let updatePublisher = publisher ?? defaultPublisher
        
        
        updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateInfo() {
        
        let newString = stringGenerator.getString(from: event, at: Date())
        self.infoString = newString
        
    }
}


