//
//  File.swift
//  
//
//  Created by Ryan on 19/6/2024.
//

import Foundation
import Combine

public class GlobalTimerContainer: ObservableObject {
    
    public init() {
        
    }
    
    public let everySecondPublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect().map { _ in () }.eraseToAnyPublisher()
    
}
