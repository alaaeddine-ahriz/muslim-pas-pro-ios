import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        // Charge la préférence de thème depuis les UserDefaults ou utilise la préférence système
        let savedValue = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool
        let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        self.isDarkMode = savedValue ?? systemIsDark
    }
    
    // Convertit le booléen en ColorScheme pour SwiftUI
    var colorScheme: ColorScheme {
        return isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
} 