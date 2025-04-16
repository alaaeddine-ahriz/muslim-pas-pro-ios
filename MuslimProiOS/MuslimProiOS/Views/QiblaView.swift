import SwiftUI
import CoreLocation

struct QiblaView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var qiblaManager = QiblaManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if locationManager.isLoading {
                    loadingView
                } else if let error = locationManager.error {
                    errorView(message: error)
                } else if let error = qiblaManager.error {
                    errorView(message: error)
                } else if qiblaManager.isCalibrating {
                    calibrationView
                } else {
                    qiblaContent
                }
            }
            .navigationTitle("Qibla")
            .onAppear {
                startQiblaUpdates()
            }
            .onDisappear {
                qiblaManager.stopUpdating()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Chargement...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button(action: {
                startQiblaUpdates()
            }) {
                Text("Réessayer")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var calibrationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Calibration de la boussole...")
                .font(.headline)
            
            Text("Veuillez faire un mouvement en forme de 8 avec votre appareil pour calibrer la boussole.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var qiblaContent: some View {
        VStack(spacing: 30) {
            // Information sur l'emplacement
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.green)
                Text(locationManager.cityName)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Boussole de la Qibla
            ZStack {
                // Cercle extérieur
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 5)
                    .frame(width: 280, height: 280)
                
                // Marques cardinales
                ForEach(0..<4) { index in
                    let angle = Double(index) * 90.0
                    let direction = getCardinalDirection(for: angle)
                    
                    VStack {
                        Text(direction)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: -130)
                    .rotationEffect(.degrees(angle))
                }
                
                // Flèche de la Qibla
                VStack(spacing: 0) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 2, height: 100)
                }
                .rotationEffect(.degrees(qiblaManager.qiblaDirection))
                
                // Centre de la boussole
                Circle()
                    .fill(Color.green)
                    .frame(width: 15, height: 15)
                
                // Indication Kaaba
                VStack {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                .offset(y: -110)
                .rotationEffect(.degrees(qiblaManager.qiblaDirection))
                
                // Texte de la Qibla au centre
                VStack {
                    Text("Qibla")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("\(Int(qiblaManager.qiblaDirection))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 300, height: 300)
            .padding(.vertical, 30)
            
            // Indication pour l'utilisateur
            Text("Dirigez la flèche verte vers la Kaaba")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top)
    }
    
    private func startQiblaUpdates() {
        if let location = locationManager.location {
            qiblaManager.startUpdating(with: location)
        }
    }
    
    private func getCardinalDirection(for angle: Double) -> String {
        switch angle {
        case 0: return "N"
        case 90: return "E"
        case 180: return "S"
        case 270: return "O"
        default: return ""
        }
    }
} 