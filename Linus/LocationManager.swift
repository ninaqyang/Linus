//
//  LocationManager.swift
//  Linus
//
//  Created by Nina Yang on 5/14/17.
//  Copyright © 2017 Nina Yang. All rights reserved.
//

import Foundation
import CoreLocation

//protocol LocationManagerDelegate: class {
//    func location
//    func locationDenied()
//}

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LocationManager()
    
//    weak var delegate: LocationManagerDelegate?
    fileprivate var locationManager: CLLocationManager = CLLocationManager()
    fileprivate var long: Double?
    fileprivate var lat: Double?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Location Manager Delgate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Stop updating locations")
        self.locationManager.stopUpdatingLocation()
        
        if !error.localizedDescription.isEmpty {
            print("Error: \(error)")
            // send alert vc message back to vc
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = self.locationManager.location {
            self.long = location.coordinate.longitude
            self.lat = location.coordinate.latitude
            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
        }
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
//            if let delegate = self.delegate {
//                dispatch_async(dispatch_get_main_queue()) {
//                    delegate.locationDenied()
//                }
//            } else {
//                print("Delegate nil")
//            }
            break
        }
        
        if CLLocationManager.locationServicesEnabled() {
            print("Start updating locations")
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func getCoordinateData() -> [Double]? {
        guard let long = self.long, let lat = self.lat else { return nil }
        let coordinates = [long, lat]
        return coordinates
    }
}
