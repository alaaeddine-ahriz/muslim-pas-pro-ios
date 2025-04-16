import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PrayerView()
                .tabItem {
                    Label("Prière", systemImage: "house.fill")
                }
                .tag(0)
            
            QuranView()
                .tabItem {
                    Label("Coran", systemImage: "book.fill")
                }
                .tag(1)
            
            QiblaView()
                .tabItem {
                    Label("Qibla", systemImage: "location.north.fill")
                }
                .tag(2)
        }
        .accentColor(Color("AccentColor"))
    }
} 