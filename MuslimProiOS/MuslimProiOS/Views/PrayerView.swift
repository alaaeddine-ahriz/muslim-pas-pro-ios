import SwiftUI
import CoreLocation

struct PrayerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var prayerManager = PrayerManager()
    @State private var showingSettings = false
    @State private var selectedLocation: CLLocation?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond dégradé
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.isDarkMode ? Color.black : Color.white,
                        themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.blue.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // En-tête avec la prochaine prière
                        if let nextPrayer = prayerManager.nextPrayer {
                            VStack(spacing: 10) {
                                Text("Prochaine prière")
                                    .font(.headline)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                
                                Text(nextPrayer.name.rawValue)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                
                                Text(prayerManager.formatTime(nextPrayer.time))
                                    .font(.title2)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                
                                // Compte à rebours
                                Text(formatTimeInterval(prayerManager.timeUntilNextPrayer))
                                    .font(.title3)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Liste des prières
                        LazyVStack(spacing: 15) {
                            ForEach(prayerManager.prayers, id: \.name) { prayer in
                                PrayerRow(prayer: prayer, isActive: prayerManager.isPrayerActive(prayer))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Horaires de prière")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                PrayerSettingsView(selectedLocation: $selectedLocation)
            }
            .onChange(of: selectedLocation) { newLocation in
                if let location = newLocation {
                    prayerManager.currentLocation = location
                    Task {
                        await prayerManager.updatePrayers()
                    }
                }
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct PrayerRow: View {
    let prayer: Prayer
    let isActive: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(prayer.name.rawValue)
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            Text(formatTime(prayer.time))
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? (themeManager.isDarkMode ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)) : Color.clear)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct PrayerSettingsView: View {
    @Binding var selectedLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Localisation")) {
                    if let location = locationManager.location {
                        Text("Latitude: \(location.coordinate.latitude)")
                        Text("Longitude: \(location.coordinate.longitude)")
                        
                        Button("Utiliser cette position") {
                            selectedLocation = location
                            dismiss()
                        }
                    } else {
                        Text("Chargement de la position...")
                    }
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrayerView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerView()
            .environmentObject(ThemeManager())
    }
} 