import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var cityName: String = ""
    @Published var isLoading: Bool = true
    @Published var error: String?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Arrêter les mises à jour après avoir obtenu une localisation
        manager.stopUpdatingLocation()
        
        // Mettre à jour la propriété de localisation
        self.location = location
        
        // Obtenir le nom de la ville
        lookUpCurrentLocation { (placemark) in
            if let placemark = placemark {
                self.cityName = placemark.locality ?? placemark.subAdministrativeArea ?? "Votre position"
            }
            self.isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Impossible d'accéder à votre localisation: \(error.localizedDescription)"
        self.isLoading = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            self.error = "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
            self.isLoading = false
        case .notDetermined:
            // L'autorisation n'a pas encore été déterminée
            break
        default:
            // Autorisé - attendre la mise à jour de l'emplacement
            break
        }
    }
    
    private func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?) -> Void) {
        // Utilisez la localisation actuelle si disponible
        if let lastLocation = self.location {
            let geocoder = CLGeocoder()
            
            // Recherchez l'emplacement inverse
            geocoder.reverseGeocodeLocation(lastLocation) { (placemarks, error) in
                if error == nil {
                    let placemark = placemarks?[0]
                    completionHandler(placemark)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
} 