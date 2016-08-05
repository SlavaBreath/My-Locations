//
//  FirstViewController.swift
//  My Locations
//
//  Created by Vyacheslav Nagornyak on 8/3/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var latitudeLabel: UILabel!
	@IBOutlet weak var longitudeLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var tagButton: UIButton!
	@IBOutlet weak var getButton: UIButton!
	
	let locationManager = CLLocationManager()
	
	var location: CLLocation?
	var updatingLocation = false
	var lastLocationError: NSError?
	
	let geocoder = CLGeocoder()
	var placemark: CLPlacemark?
	var performingReverseGeocoding = false
	var lastGeocodingError: NSError?
	
	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		updateLabels()
		configureGetButton()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - CLLocationManagerDelegate
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let newLocation = locations.last!
		print("didUpdateLocations \(newLocation)")
		
		if newLocation.timestamp.timeIntervalSinceNow < -5 {
			return
		}
		
		if newLocation.horizontalAccuracy < 0 {
			return
		}
		
		if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
			lastLocationError = nil
			location = newLocation
			updateLabels()
			
			if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
				print("*** We're done!")
				stopLocationManager()
				configureGetButton()
			}
			
			if !performingReverseGeocoding {
				print("*** Going to geocode")
				
				performingReverseGeocoding = true
				
				geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in
					print("Found placemarks: \(placemarks) error: \(error)")
					
					self.lastGeocodingError = error as? NSError
					if error == nil, let p = placemarks, !p.isEmpty {
						self.placemark = p.last!
					} else {
						self.placemark = nil
					}
					
					self.performingReverseGeocoding = false
					self.updateLabels()
				})
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("didFailWithError \(error)")
		
		if (error as NSError).code == CLError.locationUnknown.rawValue {
			return
		}
		
		lastLocationError = error as NSError
		
		stopLocationManager()
		updateLabels()
		configureGetButton()
	}
	
	// MARK:
	
	func startLocationManager() {
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
			updatingLocation = true
		}
	}
	
	func stopLocationManager() {
		if updatingLocation {
			locationManager.stopUpdatingLocation()
			locationManager.delegate = nil
			updatingLocation = false
		}
	}
	
	// MARK: - Actions
	
	@IBAction func getLocation() {
		let authStatus = CLLocationManager.authorizationStatus()
		if authStatus == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
			return
		}
		
		if authStatus == .denied || authStatus == .restricted {
			showLocationServicesDeniedAlert()
			return
		}
		
		if updatingLocation {
			stopLocationManager()
		} else {
			location = nil
			lastLocationError = nil
			placemark = nil
			lastGeocodingError = nil
			startLocationManager()
		}
		
		
		updateLabels()
		configureGetButton()
	}
	
	// MARK: - Privacy
	
	func showLocationServicesDeniedAlert() {
		let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app is Settings", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(okAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	// MARK: - Visual configurations
	
	func updateLabels() {
		if let location = location {
			latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
			longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
			tagButton.isHidden = false
			messageLabel.text = ""
			
			if let placemark = placemark {
				addressLabel.text = stringFrom(placemark: placemark)
				addressLabel.sizeToFit()
			} else if performingReverseGeocoding {
				addressLabel.text = "Searching for Address..."
			} else if lastGeocodingError != nil {
				addressLabel.text = "Error Finding Address"
			} else {
				addressLabel.text = "No Address Found"
			}
		} else {
			latitudeLabel.text = ""
			longitudeLabel.text = ""
			addressLabel.text = ""
			tagButton.isHidden = true
			
			let statusMessage: String
			if let error = lastLocationError {
				if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
					statusMessage = "Location Services Disabled"
				} else {
					statusMessage = "Error Getting Location"
				}
			} else if !CLLocationManager.locationServicesEnabled() {
				statusMessage = "Location Services Disabled"
			} else if updatingLocation {
				statusMessage = "Searching..."
			} else {
				statusMessage = "Tap 'Get My Location' to Start"
			}
			messageLabel.text = statusMessage
		}
	}
	
	func configureGetButton() {
		if updatingLocation {
			getButton.setTitle("Stop", for: .normal)
		} else {
			getButton.setTitle("Get My Location", for: .normal)
		}
	}
	
	func stringFrom(placemark: CLPlacemark) -> String {
		var line1 = ""
		if let s = placemark.subThoroughfare {
			line1 += s + " "
		}
		if let s = placemark.thoroughfare {
			line1 += s
		}
		
		var line2 = ""
		if let s = placemark.locality {
			line2 += s + " "
		}
		if let s = placemark.administrativeArea {
			line2 += s + " "
		}
		if let s = placemark.postalCode {
			line2 += s
		}
		
		return line1 + "\n" + line2
	}
}

