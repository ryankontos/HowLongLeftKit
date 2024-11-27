//
//  MockHiddenEventManager.swift
//  HowLongLeftKit
//
//  Created by Ryan on 23/11/2024.
//

import Foundation
@testable import HowLongLeftKit

public final class MockHiddenEventManager: StoredEventManager {
    
    public init() {
        super.init(domain: "mock", limit: nil)
    }
    
    override public func isEventStoredWith(eventID: String) -> Bool {
        return false
    }
}
