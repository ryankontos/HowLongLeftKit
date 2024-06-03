//
//  TitledEventGroup.swift
//
//
//  Created by Ryan on 25/5/2024.
//

import Foundation

public class TitledEventGroup: Identifiable {
    
    public init(_ title: String?, _ events: [Event]) {
        self.title = title
        self.events = events
    }
    
    public var title: String?
    public var events: [Event]
    
    
}
