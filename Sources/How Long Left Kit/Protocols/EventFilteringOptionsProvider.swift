//
//  File.swift
//  
//
//  Created by Ryan on 19/6/2024.
//

import Foundation
import EventKit
import Combine

public protocol EventFilteringOptionsProvider: ObservableObject {
    var objectWillChange: ObservableObjectPublisher { get }
    func getAllowedCalendars(matchingContextIn contexts: Set<String>) -> [EKCalendar]
    func getAllDayAllowed() -> Bool
    func updateForNewCals()
}
