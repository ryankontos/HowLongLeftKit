//
//  File.swift
//  
//
//  Created by Ryan on 23/6/2024.
//

import Foundation
import SwiftUI

extension CalendarSource {
    
    
    public func getColor(calendarID: String) -> Color {
        
        if let col = self.lookupCalendar(withID: calendarID)?.cgColor {
            return Color(cgColor: col)
        }
        
        return .primary
            
        
        
    }
    
}
