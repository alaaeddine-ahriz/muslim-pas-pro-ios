import Foundation
import Combine

struct Surah: Identifiable, Decodable {
    let id: Int
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    
    var displayName: String {
        return "\(number). \(name) - \(englishNameTranslation)"
    }
    
    enum CodingKeys: String, CodingKey {
        case number
        case name
        case englishName
        case englishNameTranslation
        case numberOfAyahs
        case revelationType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        name = try container.decode(String.self, forKey: .name)
        englishName = try container.decode(String.self, forKey: .englishName)
        englishNameTranslation = try container.decode(String.self, forKey: .englishNameTranslation)
        numberOfAyahs = try container.decode(Int.self, forKey: .numberOfAyahs)
        revelationType = try container.decode(String.self, forKey: .revelationType)
        id = number
    }
}

struct Ayah: Identifiable, Decodable {
    let id: Int
    let number: Int
    let text: String
    let surah: Int
    let numberInSurah: Int
    
    enum CodingKeys: String, CodingKey {
        case number
        case text
        case surah
        case numberInSurah
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        text = try container.decode(String.self, forKey: .text)
        surah = try container.decode(Int.self, forKey: .surah)
        numberInSurah = try container.decode(Int.self, forKey: .numberInSurah)
        id = number
    }
    
    // Initialisation personnalisée pour les résultats de recherche
    init(id: Int, number: Int, text: String, surah: Int, numberInSurah: Int) {
        self.id = id
        self.number = number
        self.text = text
        self.surah = surah
        self.numberInSurah = numberInSurah
    }
}

struct SurahResponse: Decodable {
    let code: Int
    let status: String
    let data: [Surah]
}

struct AyahResponse: Decodable {
    let code: Int
    let status: String
    let data: AyahData
    
    struct AyahData: Decodable {
        let ayahs: [Ayah]
        let edition: Edition
        
        struct Edition: Decodable {
            let identifier: String
            let language: String
            let name: String
            let englishName: String
        }
    }
}

class QuranManager: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var currentSurah: Surah?
    @Published var ayahs: [Ayah] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let baseURL = "https://api.alquran.cloud/v1"
    
    func loadSurahs() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        let urlString = "\(baseURL)/surah"
        
        do {
            let response: SurahResponse = try await NetworkManager.shared.fetchData(from: urlString)
            
            DispatchQueue.main.async {
                self.surahs = response.data
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Erreur lors du chargement des sourates: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadAyahs(for surahNumber: Int, translation: String = "fr.hamidullah") async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
            self.ayahs = []
            self.currentSurah = self.surahs.first(where: { $0.number == surahNumber })
        }
        
        let urlString = "\(baseURL)/surah/\(surahNumber)/\(translation)"
        
        do {
            let response: AyahResponse = try await NetworkManager.shared.fetchData(from: urlString)
            
            DispatchQueue.main.async {
                self.ayahs = response.data.ayahs
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Erreur lors du chargement des versets: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func searchAyahs(query: String) async -> [Ayah] {
        guard !query.isEmpty else { return [] }
        
        let urlString = "\(baseURL)/search/\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)/fr.hamidullah"
        
        do {
            struct SearchResponse: Decodable {
                let code: Int
                let status: String
                let data: SearchData
                
                struct SearchData: Decodable {
                    let count: Int
                    let matches: [SearchMatch]
                    
                    struct SearchMatch: Decodable {
                        let number: Int
                        let text: String
                        let edition: Edition
                        let surah: Surah
                        let numberInSurah: Int
                        
                        struct Edition: Decodable {
                            let identifier: String
                            let language: String
                            let name: String
                            let englishName: String
                        }
                        
                        struct Surah: Decodable {
                            let number: Int
                            let name: String
                            let englishName: String
                            let englishNameTranslation: String
                        }
                    }
                }
            }
            
            let response: SearchResponse = try await NetworkManager.shared.fetchData(from: urlString)
            
            // Convertir les résultats de recherche en objets Ayah
            let ayahs = response.data.matches.map { match in
                return Ayah(id: match.number, 
                           number: match.number, 
                           text: match.text, 
                           surah: match.surah.number, 
                           numberInSurah: match.numberInSurah)
            }
            
            return ayahs
        } catch {
            print("Erreur lors de la recherche: \(error)")
            return []
        }
    }
} 