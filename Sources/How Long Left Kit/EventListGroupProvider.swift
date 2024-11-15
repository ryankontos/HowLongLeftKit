//
//  EventListGroupProvider.swift
//
//
//  Created by Ryan on 20/6/2024.
//

import Foundation

public class EventListGroupProvider {
    
    private let dateFormatter = DateFormatterUtility()
    
    private var listSettings: EventListSettingsManager
    
    public init(settingsManager: EventListSettingsManager) {
        self.listSettings = settingsManager
    }
    
    public func getGroups(from point: TimePoint, selected: Event?) -> EventGroups {
        
        var headerGroups = [TitledEventGroup]()
        var groups = [TitledEventGroup]()
        
        
        
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
        if let nextEvent = point.fetchSingleEvent(accordingTo: .soonestCountdownDate), nextEvent.status(at: point.date) == .upcoming {
            let group = TitledEventGroup.makeGroup(title: "Next Up", info: nil, events: [nextEvent], makeIfEmpty: true)!
            group.flags = [.prominentSection]
            nextGroup = group
        }
        
        if mode == .chronological {
            let pointGroups = point.allGroupedByCountdownDate.compactMap {
                TitledEventGroup.makeGroup(
                    title: "\(dateFormatter.formattedDateString($0.date, allowRelative: true))",
                    info: dateFormatter.getDaysAwayString(from: $0.date, at: Date()),
                    events: $0.events,
                    makeIfEmpty: listSettings.showEmptyUpcomingDays
                )
            }
            return .init(headerGroups: headerGroups, upcomingGroups: pointGroups)
        }
        
        var onNowGroup: TitledEventGroup?
        
        if listSettings.showInProgress, point.inProgressEvents.count > 0 {
            onNowGroup = TitledEventGroup.makeGroup(title: "In Progress", info: nil, events: point.inProgressEvents, makeIfEmpty: listSettings.showInProgressWhenEmpty)
        }
        
        if let nextGroup, onNowGroup == nil {
            groups.insert(nextGroup, at: 0)
        }
        
        var upcomingGrouped: [TitledEventGroup]?
        
        if listSettings.showUpcoming {
            upcomingGrouped = point.upcomingGroupedByStart.map {
                TitledEventGroup(
                    "\(dateFormatter.formattedDateString($0.date, allowRelative: true))",
                    dateFormatter.getDaysAwayString(from: $0.date, at: Date()),
                    $0.events
                )
            }
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
}
