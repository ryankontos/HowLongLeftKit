//
//  HLLCalendar.swift
//  HowLongLeftKit
//
//  Created by Ryan on 4/1/2025.
//

import Foundation
import CoreGraphics
import EventKit

public class HLLCalendar {
    
    public init(ekCalendar: EKCalendar) {
        self.calendarIdentifier = ekCalendar.calendarIdentifier
        self.title = ekCalendar.title
        self.cgColor = ekCalendar.cgColor ?? .init(genericCMYKCyan: 0, magenta: 0, yellow: 0, black: 0, alpha: 0)
    }
    
    public init(calendarIdentifier: String, title: String, color: CGColor) {
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.cgColor = color
    }
    
    public var calendarIdentifier: String
    public var title: String
    public var cgColor: CGColor
}
