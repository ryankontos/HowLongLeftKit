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
    
    public func getGroups(from point: TimePoint) -> [TitledEventGroup] {
        
        var groups = [TitledEventGroup]()
        
        let mode = listSettings.sortMode
        
        if !listSettings.showInProgress && !listSettings.showUpcoming {
            return []
        }
        
        if mode == .chronological {
            
            return point.allGroupedByCountdownDate.compactMap {
                
                TitledEventGroup.makeGroup(title: "\(dateFormatter.formattedDateString($0.date, allowRelative: true))", events: $0.events, makeIfEmpty: listSettings.showEmptyUpcomingDays)
                
                
            }
            
        }
        
        var onNowGroup: TitledEventGroup?
        
        if listSettings.showInProgress {
            onNowGroup = TitledEventGroup.makeGroup(title: "On Now", events: point.inProgressEvents, makeIfEmpty: listSettings.showInProgressWhenEmpty)
        }
        
        var upcomingGrouped: [TitledEventGroup]?
        
        if listSettings.showUpcoming {
            upcomingGrouped = point.upcomingGroupedByStart.map {
                TitledEventGroup("\(dateFormatter.formattedDateString($0.date, allowRelative: true))", $0.events)
            }
        }
        
        if listSettings.sortMode == .onNowFirst {
            
            if let onNowGroup { groups.append(onNowGroup) }
            if let upcomingGrouped { groups.append(contentsOf: upcomingGrouped) }
            
        } else if listSettings.sortMode == .upcomingFirst {
            
            if let upcomingGrouped { groups.append(contentsOf: upcomingGrouped) }
            if let onNowGroup { groups.append(onNowGroup) }
            
        }
        
        return groups
        
    }
    
}
