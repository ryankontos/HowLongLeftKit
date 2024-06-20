//
//  File.swift
//  
//
//  Created by Ryan on 19/6/2024.
//

import Foundation

public class DateFormatterUtility {
    
    public init() { }
    
    
    public func getEventIntervalString(event: Event, newLineForEnd: Bool) -> String {
        
        if event.isAllDay {
            let start = formattedDateString(event.startDate, allowRelative: true)
            let end = formattedDateString(event.endDate, allowRelative: true)
            
            return "\(start) - \(end)"
            
        }
        
        let startDate = formattedDateString(event.startDate, allowRelative: true)
        let startTime = formattedTimeString(event.startDate)
        
        let endDate = formattedDateString(event.endDate, allowRelative: true)
        let endTime = formattedTimeString(event.endDate)
        
        return "\(startDate), \(startTime) -\(newLineForEnd ? "\n" : "")\(endDate != startDate ? "\(endDate) ," : "")\(endTime)"
        
    }
    
    public func formattedTimeString(_ date: Date) -> String {
         
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = minute == 0 ? "h a" : "h:mm a"
        
        if !dateFormatter.dateFormat.contains("a") {
            dateFormatter.dateFormat = minute == 0 ? "H" : "H:mm"
        }
         
        return dateFormatter.string(from: date)
    }
    
    public func formattedDateString(_ date: Date, allowRelative: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
      
        
        if allowRelative {
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInTomorrow(date) {
                return "Tomorrow"
            }
        }
        
        
        return formatter.string(from: date)
    }

    
    
}
