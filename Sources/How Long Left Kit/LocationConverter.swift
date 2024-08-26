//
//  File.swift
//  
//
//  Created by Ryan on 18/6/2024.
//

import Foundation
import CoreLocation

import Foundation
import CoreLocation

public actor LocationCache {
    private var cache: [String: CLLocation] = [:]
    
    func getLocation(for name: String) -> CLLocation? {
        return cache[name]
    }
    
    func setLocation(_ location: CLLocation, for name: String) {
        cache[name] = location
    }
}

public struct LocationConverter {
    
    private let geocoder = CLGeocoder()
    private let cache = LocationCache()
    
    private init() {}
    
    public func convertToCLLocation(locationName: String) async throws -> CLLocation {
        // Check if the location is already in the cache
        if let cachedLocation = await cache.getLocation(for: locationName) {
            return cachedLocation
        }
        
        // Perform geocoding
        let placemarks = try await geocoder.geocodeAddressString(locationName)
        
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw NSError(domain: "LocationConverter", code: 0, userInfo: [NSLocalizedDescriptionKey: "Location not found"])
        }
        
        // Cache the location
        await cache.setLocation(location, for: locationName)
        
        return location
    }
}
