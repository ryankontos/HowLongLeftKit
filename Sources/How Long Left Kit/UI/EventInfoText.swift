//
//  SwiftUIView.swift
//  
//
//  Created by Ryan on 19/6/2024.
//

import SwiftUI

public struct EventInfoText: View {
    
    @ObservedObject private var timerContainer = GlobalTimerContainer.shared
    
    @ObservedObject private var infoStringGen: InfoStringManager
    
    private var event: Event
    
    
    
    public init(_ event: Event, stringGenerator: EventInfoStringGenerator) {
        
        self.event = event
        self.infoStringGen = InfoStringManager(event: event, stringGenerator: stringGenerator)
        
    }
    
    public var body: some View {
        Text(infoStringGen.infoString)
            .monospacedDigit()
            .onAppear() {
                infoStringGen.setPublisher(timerContainer.everySecondPublisher)
            }
            .transaction {
                $0.animation = nil
            }
    }
}

/*#Preview {
    EventCountdownText()
}*/
