//
//  File.swift
//  
//
//  Created by Ryan on 9/5/2024.
//

import Foundation
import Defaults


public class CalendarInfoContext: Equatable, Hashable, Codable, Defaults.Serializable, Identifiable {
    
    static let global = CalendarInfoContext(id: "global")
    
    static public func == (lhs: CalendarInfoContext, rhs: CalendarInfoContext) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init(id: String) {
        self.id = id
    }
    
    public let id: String
    
}
