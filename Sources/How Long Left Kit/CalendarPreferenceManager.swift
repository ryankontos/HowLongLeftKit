import Foundation
import Defaults
import Combine
import EventKit

public class CalendarPreferenceManager: ObservableObject {
    
    private let matcher = CalendarMatcher()
    private let calendarSource: CalendarSource
    
    private let calendarInfosKey: Defaults.Key<[CalendarInfo]>
    private let stateForNewCalendarsKey: Defaults.Key<CalendarInfo.State>
    private let showAllDayKey: Defaults.Key<Bool>
    
    @Published public var stateForNonMatches: CalendarInfo.State {
        didSet { Defaults[stateForNewCalendarsKey] = stateForNonMatches }
    }
    
    @Published public var showAllDay: Bool {
        didSet {
            Defaults[showAllDayKey] = showAllDay
        }
    }
    
    @Published public var calendars = [CalendarInfo]() {
        didSet { updateSubscriptions() }
    }
    
    private var notMatchedCalendars = [CalendarInfo]()
    private var cancellables: Set<AnyCancellable> = []
    
    public init(calendarSource: CalendarSource, domain: String) {
        self.calendarSource = calendarSource
       
        calendarInfosKey = Defaults.Key<[CalendarInfo]>("HLL_\(domain)_calendarInfos", default: [])
        stateForNewCalendarsKey = Defaults.Key<CalendarInfo.State>("HLL_\(domain)_includeNewCalendars", default: .enabled(.global))
        showAllDayKey = Defaults.Key<Bool>("HLL_\(domain)_showAllDayEvents", default: true)
        
        self.stateForNonMatches = Defaults[stateForNewCalendarsKey]
        self.showAllDay = Defaults[showAllDayKey]
        
        loadCalendars()
    }
    
    public func getEKCalendars(withMode: CalendarInfo.State.EnabledMode) -> [EKCalendar] {
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        let toggled = (calendars+notMatchedCalendars).filter { calendarInfo in
            if case .enabled(withMode) = calendarInfo.state {
                return true
            }
            return false
        }
            
        
        return matcher.matchCalendars(ekCalendars: allCalendars, calendarInfos: toggled)
    }
    
    public func getEKCalendar(forCalendarInfo calendarInfo: CalendarInfo) -> EKCalendar? {
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        return matcher.match(calendarInfo: calendarInfo, from: allCalendars)
    }
    
    // MARK: - Calendar Loading and Syncing
    private func loadCalendars() {
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        let existingInfos = Defaults[calendarInfosKey]
        let (matched, notMatched) = matcher.getUpdatedCalendarInfo(existing: existingInfos, userCalendars: allCalendars, stateForNonMatches: Defaults[stateForNewCalendarsKey])
        calendars = matched
        notMatchedCalendars = notMatched
        self.stateForNonMatches = Defaults[stateForNewCalendarsKey]
        self.showAllDay = Defaults[showAllDayKey]
    }
    
    private func syncCalendars() {
        let allCalendars = calendarSource.eventStore.calendars(for: .event)
        let existingInfos = calendars + notMatchedCalendars
        let nonMatchesState = Defaults[stateForNewCalendarsKey]
        let (matched, notMatched) = matcher.getUpdatedCalendarInfo(existing: existingInfos, userCalendars: allCalendars, stateForNonMatches: nonMatchesState)
        Defaults[calendarInfosKey] = matched + notMatched
    }
    
    // MARK: - Subscriptions Management
    private func updateSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        calendars.forEach { calendarInfo in
            calendarInfo.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.calendarInfoDidChange(calendarInfo)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func calendarInfoDidChange(_ calendarInfo: CalendarInfo) {
        syncCalendars()
        objectWillChange.send()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
}
