import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetch<T: Decodable>(url: URL) -> AnyPublisher<T, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchData<T: Decodable>(from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    // Fonction pour obtenir la date hégirienne
    func fetchHijriDate() async -> String {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: today)
        
        let urlString = "https://api.aladhan.com/v1/gToH/\(dateString)"
        
        do {
            struct HijriResponse: Decodable {
                let code: Int
                let data: HijriData
                
                struct HijriData: Decodable {
                    let hijri: Hijri
                    
                    struct Hijri: Decodable {
                        let day: String
                        let month: Month
                        let year: String
                        
                        struct Month: Decodable {
                            let en: String
                        }
                    }
                }
            }
            
            let response: HijriResponse = try await fetchData(from: urlString)
            
            if response.code == 200 {
                // Mapping des mois hijri en français
                let hijriMonths: [String: String] = [
                    "Muharram": "Mouharram",
                    "Safar": "Safar",
                    "Rabi al-awwal": "Rabi al-Awwal",
                    "Rabi al-thani": "Rabi al-Thani",
                    "Jumada al-awwal": "Joumada al-Oula",
                    "Jumada al-thani": "Joumada al-Thania",
                    "Rajab": "Rajab",
                    "Shaban": "Chaabane",
                    "Ramadan": "Ramadan",
                    "Shawwal": "Chawwal",
                    "Dhu al-Qadah": "Dhou al-Qida",
                    "Dhu al-Hijjah": "Dhou al-Hijja"
                ]
                
                let hijriData = response.data.hijri
                let monthName = hijriMonths[hijriData.month.en] ?? hijriData.month.en
                return "\(hijriData.day) \(monthName) \(hijriData.year)"
            } else {
                return ""
            }
        } catch {
            print("Erreur lors de la récupération de la date hégirienne: \(error)")
            return ""
        }
    }
} 