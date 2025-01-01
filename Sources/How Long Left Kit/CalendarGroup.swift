//
//  File.swift
//  HowLongLeftKit
//
//  Created by Ryan on 2/1/2025.
//

import Foundation
import EventKit
 
class CalendarGroup {
    
    var calendarID: String
    
    var timePoints: [TimePoint]
    
    init(calendarID: String, timePoints: [TimePoint]) {
        self.calendarID = calendarID
        self.timePoints = timePoints
    }
    
}
