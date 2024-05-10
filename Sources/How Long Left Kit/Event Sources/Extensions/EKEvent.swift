//
//  File.swift
//  
//
//  Created by Ryan on 6/5/2024.
//

import Foundation
import EventKit

extension EKEvent: Identifiable {
    
    public var id: String {
        return "\(eventIdentifier!)\(startDate!)"
    }
    
}
