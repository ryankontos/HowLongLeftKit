//
//  CalendarMatcher.swift
//  How Long Left
//
//  Created by Ryan on 7/5/2024.
//

import Foundation
import EventKit

class CalendarMatcher {
    
    func matchCalendars(ekCalendars: [EKCalendar], calendarInfos: [CalendarInfo]) -> [EKCalendar] {
        
        var returnCalendars = [EKCalendar]()
        
        for ekCalendar in ekCalendars {
            if calendarInfos.contains(where: { $0.id == ekCalendar.calendarIdentifier }) || calendarInfos.contains(where: { $0.title == ekCalendar.title }) {
                returnCalendars.append(ekCalendar)
            }
        }
        
        return returnCalendars
    }
    
    func match(calendarInfo: CalendarInfo, from ekCalendars: [EKCalendar]) -> EKCalendar? {
        return ekCalendars.first(where: { $0.calendarIdentifier == calendarInfo.id })
    }
    
    func getUpdatedCalendarInfo(existing calendarInfos: [CalendarInfo], userCalendars: [EKCalendar], stateForNonMatches: CalendarInfo.State) -> (matched: [CalendarInfo], notMatched: [CalendarInfo]){
        var updatedCalendars = [CalendarInfo]()
        var noMatchCals = [CalendarInfo]()

        // First, handle calendars from userCalendars
        for ekCalendar in userCalendars {
            if let match = calendarInfos.first(where: { $0.id == ekCalendar.calendarIdentifier }) ?? calendarInfos.first(where: { $0.title == ekCalendar.title }) {
                // Found a matching CalendarInfo, update and add to the result
                updatedCalendars.append(CalendarInfo(ekCalendar, state: match.state))
            } else {
                // No match found and includeNonMatches is true, add new CalendarInfo with default toggled
                updatedCalendars.append(CalendarInfo(ekCalendar, state: stateForNonMatches))
            }
        }

        // Now, add CalendarInfos from existing that did not match any ekCalendar
        let updatedIdentifiers = Set(updatedCalendars.map { $0.id })
        for calendarInfo in calendarInfos where !updatedIdentifiers.contains(calendarInfo.id) {
            noMatchCals.append(calendarInfo)
        }

        return (updatedCalendars, noMatchCals)
    }


}
