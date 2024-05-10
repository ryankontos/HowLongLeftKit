//
//  File.swift
//  
//
//  Created by Ryan on 7/5/2024.
//

import Foundation
import EventKit
import Defaults

public class CalendarInfo: ObservableObject, Codable, Hashable, Identifiable, Defaults.Serializable {
    
    static public func == (lhs: CalendarInfo, rhs: CalendarInfo) -> Bool {
        return lhs.title == rhs.title && lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }
    
    convenience init(_ calendar: EKCalendar, state: State) {
       self.init(title: calendar.title, id: calendar.calendarIdentifier, state: state)
    }
    
    public init(title: String, id: String, state: State) {
        self.title = title
        self.id = id
        self.state = state
    }
    
    public var title: String
    public var id: String
    @Published public private(set) var state: State {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    
    public func updateState(newState: State) {
            self.state = newState
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        }
    
    // Codable conformance with custom encoding and decoding
    enum CodingKeys: String, CodingKey {
        case title
        case id
        case state
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        id = try container.decode(String.self, forKey: .id)
        state = try container.decode(State.self, forKey: .state)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(id, forKey: .id)
        try container.encode(state, forKey: .state)
    }
    
    public enum State: Codable, Defaults.Serializable {
        case disabled
        case enabled(EnabledMode)
        
        
        public enum EnabledMode: String, Codable, Defaults.Serializable {
            case global
            case statusItemOnly
        }
    }
    
}

