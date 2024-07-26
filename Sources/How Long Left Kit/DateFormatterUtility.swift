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
    
    public func formattedDateString(_ date: Date, allowRelative: Bool = true, includeDayOfWeek: Bool = true) -> String {
        let formatter = DateFormatter()
        
        if includeDayOfWeek {
            formatter.dateFormat = "EEEE, d MMMM"
        } else {
            formatter.dateFormat = "d MMMM"
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let dateYear = Calendar.current.component(.year, from: date)
        
        if currentYear != dateYear {
            formatter.dateFormat += " yyyy"
        }
        
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

    
    public func getDaysAwayString(from date: Date, at currentDate: Date, miniumumDays: Int? = 2) -> String? {
        // Get the current calendar
        let calendar = Calendar.current
        
        // Get the current date at midnight
        let currentDate = calendar.startOfDay(for: currentDate)
        
        // Get the input date at midnight
        let inputDate = calendar.startOfDay(for: date)
        
        // Calculate the difference in days
        let components = calendar.dateComponents([.day], from: currentDate, to: inputDate)
        
        guard let days = components.day else {
            return nil
        }
            
        if let miniumumDays {
            if days < miniumumDays {
                return nil
            }
        }
         
        // Return the appropriate string
        let val = "\(days) day" + (days == 1 ? " away" : "s away")
        
       // print("Days away string: \(val)")
       
        return val
    }
    
    
}
