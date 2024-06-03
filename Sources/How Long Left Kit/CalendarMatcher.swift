//
//  CalendarMatcher.swift
//  How Long Left
//
//  Created by Ryan on 7/5/2024.
//

import Foundation
import EventKit
import CoreData
/*
class CalendarMatcher {
    
    init(context: NSManagedObjectContext, domain: CalendarStorageDomain) {
        self.context = context
        self.domain = domain
    }
    
    let context: NSManagedObjectContext
    let domain: CalendarStorageDomain
    
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
    
    func getUpdatedCalendarInfo(existing calendarInfos: [CalendarInfo], userCalendars: [EKCalendar], contextsForNonMatches: Set<CalendarContext>) -> (matched: [CalendarInfo], notMatched: [CalendarInfo]){
        var updatedCalendars = [CalendarInfo]()
        var noMatchCals = [CalendarInfo]()

        // First, handle calendars from userCalendars
        for ekCalendar in userCalendars {
            if let match = calendarInfos.first(where: { $0.id == ekCalendar.calendarIdentifier }) ?? calendarInfos.first(where: { $0.title == ekCalendar.title }) {
                // Found a matching CalendarInfo, update and add to the result
                match.title = ekCalendar.title
                match.id = ekCalendar.calendarIdentifier
                
            } else {
                
                let info = CalendarInfo(context: context)
                info.title = ekCalendar.title
                info.id = ekCalendar.calendarIdentifier
                
            }
        }

        return (updatedCalendars, noMatchCals)
    }


}
*/
