import Foundation
import CoreLocation
import Combine
import CoreMotion
import SwiftUI

class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var qiblaDirection: Double = 0
    @Published var isCalibrating: Bool = true
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private var currentHeading: Double = 0
    private var qiblaAngle: Double = 0
    
    override init() {
        super.init()
        setupLocationManager()
        setupMotionManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else {
                    self?.error = error?.localizedDescription
                    return
                }
                
                // Obtenir l'angle actuel de la boussole par rapport au nord magnétique
                let heading = self.calculateHeading(from: motion)
                self.currentHeading = heading
                
                // Calculer l'angle de la Qibla par rapport à la position actuelle
                self.qiblaDirection = (self.qiblaAngle - heading + 360).truncatingRemainder(dividingBy: 360)
                
                if self.isCalibrating {
                    self.isCalibrating = false
                }
            }
        } else {
            error = "La boussole n'est pas disponible sur cet appareil."
        }
    }
    
    func startUpdating(with location: CLLocation) {
        // Calculer l'angle de la Qibla pour la position actuelle
        calculateQiblaAngle(from: location)
    }
    
    func stopUpdating() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func calculateQiblaAngle(from location: CLLocation) {
        // Coordonnées de la Kaaba à La Mecque
        let kaaba = CLLocation(latitude: 21.4225, longitude: 39.8262)
        
        // Conversion des coordonnées en radians
        let latKaaba = kaaba.coordinate.latitude * .pi / 180
        let lonKaaba = kaaba.coordinate.longitude * .pi / 180
        let latUser = location.coordinate.latitude * .pi / 180
        let lonUser = location.coordinate.longitude * .pi / 180
        
        // Calcul de l'angle de la Qibla
        let y = sin(lonKaaba - lonUser)
        let x = cos(latUser) * tan(latKaaba) - sin(latUser) * cos(lonKaaba - lonUser)
        let qiblaRadians = atan2(y, x)
        
        // Conversion en degrés et normalisation (0-360)
        var qiblaDegrees = qiblaRadians * 180 / .pi
        if qiblaDegrees < 0 {
            qiblaDegrees += 360
        }
        
        qiblaAngle = qiblaDegrees
    }
    
    private func calculateHeading(from motion: CMDeviceMotion) -> Double {
        // Obtenir l'orientation de l'appareil
        let attitude = motion.attitude
        
        // Convertir l'orientation en angle par rapport au nord magnétique
        let heading = atan2(attitude.rotationMatrix.m21, attitude.rotationMatrix.m11)
        
        // Convertir en degrés (0-360)
        var degrees = heading * 180 / .pi
        if degrees < 0 {
            degrees += 360
        }
        
        return degrees
    }
    
    // Implémentation des méthodes de CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        startUpdating(with: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Erreur de localisation: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            error = "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
        default:
            break
        }
    }
}

// MARK: - Preview
struct QiblaManager_Previews: PreviewProvider {
    static var previews: some View {
        QiblaPreviewView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
            .previewDisplayName("iPhone 15 Pro")
            .preferredColorScheme(.dark)
    }
}

struct QiblaPreviewView: View {
    @StateObject private var qiblaManager = QiblaManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Direction de la Qibla")
                    .font(.title)
                    .padding()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    // Aiguille de la Qibla
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 100)
                        .offset(y: -50)
                        .rotationEffect(.degrees(qiblaManager.qiblaDirection))
                    
                    // Indicateur Nord
                    Text("N")
                        .font(.caption)
                        .offset(y: -110)
                    
                    // Indicateur Est
                    Text("E")
                        .font(.caption)
                        .offset(x: 110)
                    
                    // Indicateur Sud
                    Text("S")
                        .font(.caption)
                        .offset(y: 110)
                    
                    // Indicateur Ouest
                    Text("O")
                        .font(.caption)
                        .offset(x: -110)
                }
                
                Text(String(format: "%.1f°", qiblaManager.qiblaDirection))
                    .font(.title)
                    .padding()
                
                if qiblaManager.isCalibrating {
                    Text("Calibration en cours...")
                        .foregroundColor(.orange)
                }
                
                if let error = qiblaManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 