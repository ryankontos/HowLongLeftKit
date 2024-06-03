//
//  File.swift
//  
//
//  Created by Ryan on 7/5/2024.
//

import Foundation
import EventKit
import Defaults
/*
public class CalendarInfo: ObservableObject, Codable, Hashable, Identifiable, Defaults.Serializable {
    
    static public func == (lhs: CalendarInfo, rhs: CalendarInfo) -> Bool {
        return lhs.title == rhs.title && lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }
    
    convenience init(_ calendar: EKCalendar, allowedContexts: Set<String>) {
       self.init(title: calendar.title, id: calendar.calendarIdentifier, allowedContexts: allowedContexts)
    }
    
    public init(title: String, id: String, allowedContexts: Set<String>) {
        self.title = title
        self.id = id
        self.allowedContexts = allowedContexts
    }
    
    public var title: String
    public var id: String
    @Published public var allowedContexts: Set<String> {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    
    // Codable conformance with custom encoding and decoding
    enum CodingKeys: String, CodingKey {
        case title
        case id
        case allowedContexts
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        id = try container.decode(String.self, forKey: .id)
        allowedContexts = try container.decode(Set<String>.self, forKey: .allowedContexts)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(id, forKey: .id)
        try container.encode(allowedContexts, forKey: .allowedContexts)
    }
    
    
    
}

*/
