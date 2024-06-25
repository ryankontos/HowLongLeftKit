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
        return getIntervalString(start: event.startDate, end: event.endDate, isAllDay: event.isAllDay, newLineForEnd: newLineForEnd)
    }
    
    public func getIntervalString(start: Date, end: Date, isAllDay: Bool, newLineForEnd: Bool) -> String {
        
        if isAllDay {
            let start = formattedDateString(start, allowRelative: true)
            let end = formattedDateString(end, allowRelative: true)
            
            return "\(start) - \(end)"
            
        }
        
        let startDate = formattedDateString(start, allowRelative: true)
        let startTime = formattedTimeString(start)
        
        let endDate = formattedDateString(end, allowRelative: true)
        let endTime = formattedTimeString(end)
        
        return "\(startDate), \(startTime) -\(newLineForEnd ? "\n" : " ")\(endDate != startDate ? "\(endDate) ," : "")\(endTime)"
        
    }
    
    public func formattedDateTimeString(_ date: Date, allowRelativeDate: Bool = true) -> String {
        
        let dateString = formattedDateString(date, allowRelative: allowRelativeDate)
        let timeString = formattedTimeString(date)
        return "\(dateString), \(timeString)"
        
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
