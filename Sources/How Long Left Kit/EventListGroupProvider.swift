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
    
    public func getGroups(from point: TimePoint, selected: Event?) -> [TitledEventGroup] {
        
        var groups = [TitledEventGroup]()
        
        if let selected {
            groups.append(TitledEventGroup.makeGroup(title: "Pinned", info: nil, events: [selected], makeIfEmpty: true)!)
        }
        
       
        
        let mode = listSettings.sortMode
        
        if !listSettings.showInProgress && !listSettings.showUpcoming {
            return groups
        }
        
        if mode == .chronological {
            
            let pointGroups = point.allGroupedByCountdownDate.compactMap {
                
                TitledEventGroup.makeGroup(title: "\(dateFormatter.formattedDateString($0.date, allowRelative: true))", info: dateFormatter.getDaysAwayString(from: $0.date, at: Date()), events: $0.events, makeIfEmpty: listSettings.showEmptyUpcomingDays)
                
            }
            
            return groups + pointGroups
            
        }
        
        
        var onNowGroup: TitledEventGroup?
        
        if listSettings.showInProgress {
            onNowGroup = TitledEventGroup.makeGroup(title: "In Progress", info: nil, events: point.inProgressEvents, makeIfEmpty: listSettings.showInProgressWhenEmpty)
        }
        
        var upcomingGrouped: [TitledEventGroup]?
        
        if listSettings.showUpcoming {
            upcomingGrouped = point.upcomingGroupedByStart.map {
                TitledEventGroup("\(dateFormatter.formattedDateString($0.date, allowRelative: true))", dateFormatter.getDaysAwayString(from: $0.date, at: Date()),$0.events)
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
