import Foundation
import CoreLocation
import Combine

// Types pour le calcul des heures de prière
enum CalculationMethod: Int {
    case muslimWorldLeague = 1
    case egyptian = 2
    case karachi = 3
    case isna = 4
    case mwl = 5
    case makkah = 6
    case tehran = 7
    case shia = 8
}

enum AsrJuristic: Int {
    case shafii = 1
    case hanafi = 2
}

enum AdjustHighLats: Int {
    case none = 0
    case midnight = 1
    case oneSeventh = 2
    case angleBased = 3
}

enum TimeFormat: Int {
    case time24 = 0
    case time12 = 1
    case time12NS = 2
    case float = 3
}

struct Coordinates {
    let latitude: Double
    let longitude: Double
}

struct CalculationParameters {
    let method: CalculationMethod
    let asrJuristic: AsrJuristic
    let adjustHighLats: AdjustHighLats
    let timeFormat: TimeFormat
}

struct PrayerTimes {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    
    init(coordinates: Coordinates, date: Date, calculationParameters: CalculationParameters) async throws {
        // Simulation des heures de prière pour le moment
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: components)!
        
        self.fajr = calendar.date(bySettingHour: 5, minute: 30, second: 0, of: startOfDay)!
        self.sunrise = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: startOfDay)!
        self.dhuhr = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: startOfDay)!
        self.asr = calendar.date(bySettingHour: 15, minute: 45, second: 0, of: startOfDay)!
        self.maghrib = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: startOfDay)!
        self.isha = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startOfDay)!
    }
}

enum PrayerName: String, CaseIterable {
    case fajr = "Fajr"
    case sunrise = "Lever du soleil"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"
}

struct Prayer {
    let name: PrayerName
    let time: Date
}

@MainActor
final class PrayerManager: NSObject, ObservableObject, CLLocationManagerDelegate, Sendable {
    @Published var prayers: [Prayer] = []
    @Published var nextPrayer: Prayer?
    @Published var timeUntilNextPrayer: TimeInterval = 0
    @Published var currentLocation: CLLocation?
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var calculationMethod: CalculationMethod = .muslimWorldLeague
    private var asrJuristic: AsrJuristic = .shafii
    private var adjustHighLats: AdjustHighLats = .none
    private var timeFormat: TimeFormat = .time24
    
    override init() {
        super.init()
        setupLocationManager()
        loadSavedLocation()
        startUpdatingPrayers()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func loadSavedLocation() {
        if let latitude = UserDefaults.standard.object(forKey: "savedLatitude") as? Double,
           let longitude = UserDefaults.standard.object(forKey: "savedLongitude") as? Double {
            currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    private func saveLocation(_ location: CLLocation) {
        UserDefaults.standard.set(location.coordinate.latitude, forKey: "savedLatitude")
        UserDefaults.standard.set(location.coordinate.longitude, forKey: "savedLongitude")
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    private func startUpdatingPrayers() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updatePrayers()
            }
        }
        timer?.fire()
    }
    
    func updatePrayers() async {
        guard let location = currentLocation else { return }
        
        let coordinates = Coordinates(latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude)
        let params = CalculationParameters(method: calculationMethod,
                                         asrJuristic: asrJuristic,
                                         adjustHighLats: adjustHighLats,
                                         timeFormat: timeFormat)
        
        do {
            let prayerTimes = try await PrayerTimes(coordinates: coordinates,
                                                  date: Date(),
                                                  calculationParameters: params)
            
            let newPrayers = [
                Prayer(name: .fajr, time: prayerTimes.fajr),
                Prayer(name: .sunrise, time: prayerTimes.sunrise),
                Prayer(name: .dhuhr, time: prayerTimes.dhuhr),
                Prayer(name: .asr, time: prayerTimes.asr),
                Prayer(name: .maghrib, time: prayerTimes.maghrib),
                Prayer(name: .isha, time: prayerTimes.isha)
            ]
            
            await MainActor.run {
                self.prayers = newPrayers
                self.updateNextPrayer()
            }
        } catch {
            await MainActor.run {
                self.error = "Erreur lors du calcul des horaires: \(error.localizedDescription)"
            }
        }
    }
    
    private func updateNextPrayer() {
        let now = Date()
        let upcomingPrayers = prayers.filter { $0.time > now }
        
        if let next = upcomingPrayers.first {
            nextPrayer = next
            timeUntilNextPrayer = next.time.timeIntervalSince(now)
        } else if let firstPrayerTomorrow = prayers.first {
            // Si tous les prières d'aujourd'hui sont passées, on prend la première de demain
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            let components = Calendar.current.dateComponents([.hour, .minute, .second],
                                                           from: firstPrayerTomorrow.time)
            if let nextPrayerTime = Calendar.current.date(bySettingHour: components.hour ?? 0,
                                                        minute: components.minute ?? 0,
                                                        second: components.second ?? 0,
                                                        of: tomorrow) {
                nextPrayer = Prayer(name: firstPrayerTomorrow.name, time: nextPrayerTime)
                timeUntilNextPrayer = nextPrayerTime.timeIntervalSince(now)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    @preconcurrency
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.saveLocation(location)
            await self.updatePrayers()
        }
    }
    
    @preconcurrency
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = "Erreur de localisation: \(error.localizedDescription)"
        }
    }
    
    @preconcurrency
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.error = "L'accès à la localisation a été refusé. Veuillez l'activer dans les paramètres."
            default:
                break
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func isPrayerActive(_ prayer: Prayer) -> Bool {
        let now = Date()
        
        // Vérifier si l'heure actuelle est entre cette prière et la suivante
        if let index = prayers.firstIndex(where: { $0.name == prayer.name }) {
            let nextIndex = index + 1
            
            if nextIndex < prayers.count {
                let nextPrayer = prayers[nextIndex]
                return prayer.time <= now && now < nextPrayer.time
            } else {
                // C'est la dernière prière de la journée
                let calendar = Calendar.current
                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: prayers[0].time) {
                    return prayer.time <= now && now < tomorrow
                }
            }
        }
        
        return false
    }
} 