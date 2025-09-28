//
//  LocationManager.swift
//  LovedOnes
//
//  Location tracking and geofencing for Alzheimer's patients
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: String?
    @Published var lastKnownLocation: CLLocation?
    @Published var isLocationEnabled = false
    @Published var locationHistory: [LocationEntry] = []
    @Published var geofenceAlerts: [GeofenceAlert] = []
    @Published var safeZones: [SafeZone] = []
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
        loadSampleData()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isLocationEnabled = false
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
            startLocationUpdates()
        @unknown default:
            isLocationEnabled = false
        }
    }
    
    private func startLocationUpdates() {
        guard isLocationEnabled else { return }
        locationManager.startUpdatingLocation()
    }
    
    private func loadSampleData() {
        // Sample location history
        locationHistory = [
            LocationEntry(
                date: Date().addingTimeInterval(-3600),
                latitude: 37.7749,
                longitude: -122.4194,
                address: "123 Main St, San Francisco, CA",
                isSafe: true
            ),
            LocationEntry(
                date: Date().addingTimeInterval(-7200),
                latitude: 37.7849,
                longitude: -122.4094,
                address: "456 Oak Ave, San Francisco, CA",
                isSafe: true
            ),
            LocationEntry(
                date: Date().addingTimeInterval(-10800),
                latitude: 37.7649,
                longitude: -122.4294,
                address: "789 Pine St, San Francisco, CA",
                isSafe: false
            )
        ]
        
        // Sample safe zones
        safeZones = [
            SafeZone(
                name: "Home",
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 100,
                isActive: true
            ),
            SafeZone(
                name: "Park",
                center: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                radius: 200,
                isActive: true
            ),
            SafeZone(
                name: "Doctor's Office",
                center: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
                radius: 50,
                isActive: false
            )
        ]
        
        // Sample geofence alerts
        geofenceAlerts = [
            GeofenceAlert(
                date: Date().addingTimeInterval(-1800),
                type: .exitedSafeZone,
                location: "Home",
                message: "Patient left home area"
            ),
            GeofenceAlert(
                date: Date().addingTimeInterval(-3600),
                type: .enteredSafeZone,
                location: "Park",
                message: "Patient entered park area"
            )
        ]
    }
    
    func startLocationTracking() {
        guard isLocationEnabled else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func addSafeZone(name: String, center: CLLocationCoordinate2D, radius: Double) {
        let newZone = SafeZone(name: name, center: center, radius: radius, isActive: true)
        safeZones.append(newZone)
        setupGeofencing(for: newZone)
    }
    
    private func setupGeofencing(for zone: SafeZone) {
        let region = CLCircularRegion(
            center: zone.center,
            radius: zone.radius,
            identifier: zone.name
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func getLocationHistory(for days: Int) -> [LocationEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return locationHistory.filter { $0.date >= cutoffDate }
    }
    
    func getWanderingEvents() -> [WanderingEvent] {
        return locationHistory
            .filter { !$0.isSafe }
            .map { entry in
                WanderingEvent(
                    date: entry.date,
                    location: entry.address,
                    duration: 30, // Calculate based on time spent
                    triggered: true
                )
            }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastKnownLocation = location
        
        // Reverse geocode to get address
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let placemark = placemarks?.first {
                let address = self.formatAddress(from: placemark)
                DispatchQueue.main.async {
                    self.currentLocation = address
                    
                    // Add to location history
                    let newEntry = LocationEntry(
                        date: Date(),
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        address: address,
                        isSafe: self.isLocationSafe(location)
                    )
                    self.locationHistory.insert(newEntry, at: 0)
                    
                    // Limit history to last 1000 entries
                    if self.locationHistory.count > 1000 {
                        self.locationHistory = Array(self.locationHistory.prefix(1000))
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
            startLocationUpdates()
        case .denied, .restricted:
            isLocationEnabled = false
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            isLocationEnabled = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            let alert = GeofenceAlert(
                date: Date(),
                type: .enteredSafeZone,
                location: circularRegion.identifier,
                message: "Patient entered \(circularRegion.identifier)"
            )
            geofenceAlerts.insert(alert, at: 0)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            let alert = GeofenceAlert(
                date: Date(),
                type: .exitedSafeZone,
                location: circularRegion.identifier,
                message: "Patient left \(circularRegion.identifier)"
            )
            geofenceAlerts.insert(alert, at: 0)
        }
    }
}

// MARK: - Helper Methods

extension LocationManager {
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        
        if let zipCode = placemark.postalCode {
            addressComponents.append(zipCode)
        }
        
        return addressComponents.joined(separator: " ")
    }
    
    private func isLocationSafe(_ location: CLLocation) -> Bool {
        return safeZones.contains { zone in
            let distance = location.distance(from: CLLocation(
                latitude: zone.center.latitude,
                longitude: zone.center.longitude
            ))
            return distance <= zone.radius
        }
    }
}

// MARK: - Data Models

struct LocationEntry: Identifiable {
    let id = UUID()
    let date: Date
    let latitude: Double
    let longitude: Double
    let address: String
    let isSafe: Bool
}

struct SafeZone: Identifiable {
    let id = UUID()
    let name: String
    let center: CLLocationCoordinate2D
    let radius: Double
    let isActive: Bool
}

struct GeofenceAlert: Identifiable {
    let id = UUID()
    let date: Date
    let type: GeofenceAlertType
    let location: String
    let message: String
}

enum GeofenceAlertType {
    case enteredSafeZone
    case exitedSafeZone
    case wanderingDetected
    case locationUnknown
}

