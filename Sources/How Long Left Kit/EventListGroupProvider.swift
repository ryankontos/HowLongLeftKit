//
//  EventListGroupProvider.swift
//
//
//  Created by Ryan on 20/6/2024.
//

import Foundation

public class EventListGroupProvider {
    
    private let dateFormatter = DateFormatterUtility()
    
    private var listSettings: EventListSettingsFetcher
    
    public init(settingsManager: EventListSettingsFetcher) {
        self.listSettings = settingsManager
    }
    
    public func getGroups(from point: TimePoint, selected: Event?) -> EventGroups {
        
        //print("Get event groups")
        
        var headerGroups = [TitledEventGroup]()
        var groups = [TitledEventGroup]()
        
   
        let upcomingEventDates = groupEventsByDate(point.upcomingEvents, by: .start, fillEmptyDates: listSettings.showEmptyUpcomingDays)
        
        var upcomingGrouped: [TitledEventGroup]? = upcomingEventDates.compactMap {
            TitledEventGroup.makeGroup(
                title: "\(dateFormatter.formattedDateString($0.date, allowRelative: true))",
                info: nil,
                events: $0.events,
                makeIfEmpty: listSettings.showEmptyUpcomingDays
            )
        }
        
        
        // Include a pinned section if a specific event is selected
        if let selected {
            headerGroups.append(TitledEventGroup.makeGroup(title: "Pinned", info: nil, events: [selected], makeIfEmpty: true)!)
        }
       
        if point.allEvents.isEmpty { return .init(headerGroups: headerGroups, upcomingGroups: []) }
        
        let mode = listSettings.sortMode
        
        if !listSettings.showInProgress && !listSettings.showUpcoming {
            return .init(headerGroups: headerGroups, upcomingGroups: [])
        }
        
        var nextGroup: TitledEventGroup?
        
        // Create an optional group for the next upcoming event with a prominent flag
        /*if let nextEvent = point.fetchSingleEvent(accordingTo: .soonestCountdownDate), nextEvent.status(at: point.date) == .upcoming {
            let group = TitledEventGroup.makeGroup(title: "Next Up", info: nil, events: [nextEvent], makeIfEmpty: true)!
            group.flags = [.prominentSection]
            nextGroup = group
        } */
        
        if mode == .chronological {
            
           
            return .init(headerGroups: headerGroups, upcomingGroups: upcomingGrouped ?? [])
        }
        
        var onNowGroup: TitledEventGroup?
        
        if listSettings.showInProgress, point.inProgressEvents.count > 0 {
            onNowGroup = TitledEventGroup.makeGroup(title: "In Progress", info: nil, events: point.inProgressEvents, makeIfEmpty: listSettings.showInProgressWhenEmpty)
        }
        
        if let nextGroup, onNowGroup == nil {
            groups.insert(nextGroup, at: 0)
        }
        
       
        
        if !listSettings.showUpcoming {
            upcomingGrouped = nil
        }
        
        if listSettings.sortMode == .onNowFirst {
            if let onNowGroup { headerGroups.append(onNowGroup) }
            if let upcomingGrouped { groups.append(contentsOf: upcomingGrouped) }
            
        } else if listSettings.sortMode == .upcomingFirst {
            if let upcomingGrouped { groups.append(contentsOf: upcomingGrouped) }
            if let onNowGroup { headerGroups.append(onNowGroup) }
        }
        
        return .init(headerGroups: headerGroups, upcomingGroups: groups)
    }
    
    func groupEventsByDate(_ events: [Event], at date: Date = Date(), by groupingMode: GroupMode, fillEmptyDates: Bool = true) -> [EventDate] {
        var eventDictionary = [Date: [Event]]()
        let calendar = Calendar.current

        for event in events {
            var groupUsing: Date
            
            switch groupingMode {
            case .start:
                groupUsing = event.startDate
            case .countdownDate:
                groupUsing = event.countdownDate(at: date)
            }
            
            if listSettings.showAllMultiDayEventDays {
                let startOfDay = calendar.startOfDay(for: groupUsing)
                let endOfDay = calendar.startOfDay(for: event.endDate)
                var currentDate = startOfDay
                
                while currentDate <= endOfDay {
                    eventDictionary[currentDate, default: []].append(event)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
            } else {
                let startOfDay = calendar.startOfDay(for: groupUsing)
                eventDictionary[startOfDay, default: []].append(event)
            }
        }

        
        if fillEmptyDates {
            let allDates = eventDictionary.keys.sorted()
            if let firstDate = allDates.first, let lastDate = allDates.last {
                var currentDate = firstDate
                while currentDate <= lastDate {
                    if eventDictionary[currentDate] == nil {
                        eventDictionary[currentDate] = []
                    }
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
            }
        }

        return eventDictionary.map { EventDate(date: $0.key, events: $0.value) }.sorted { $0.date < $1.date }
    }

    
    public enum GroupMode {
        case start
        case countdownDate
    }
    
}
