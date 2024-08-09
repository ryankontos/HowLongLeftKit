//
//  SwiftUIView.swift
//  
//
//  Created by Ryan on 19/6/2024.
//

import SwiftUI

public struct EventCountdownText: View {
    
    @EnvironmentObject private var timerContainer: GlobalTimerContainer
    
    @ObservedObject private var infoStringGen: InfoStringManager
    
    @ObservedObject private var event: Event
    
    
    
    public init(_ event: Event) {
        
        self.event = event
        self.infoStringGen = InfoStringManager(event: event, stringGenerator: EventCountdownTextGenerator())
        
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
