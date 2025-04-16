import SwiftUI

struct QuranView: View {
    @StateObject private var quranManager = QuranManager()
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var searchResults: [Ayah] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            Group {
                if quranManager.isLoading {
                    loadingView
                } else if let error = quranManager.error {
                    errorView(message: error)
                } else if quranManager.currentSurah != nil {
                    ayahsView
                } else if showSearch && !searchText.isEmpty {
                    searchResultsView
                } else {
                    surahsListView
                }
            }
            .navigationTitle("Coran")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showSearch.toggle()
                        }
                    }) {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                    }
                }
                
                if quranManager.currentSurah != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation {
                                quranManager.currentSurah = nil
                                quranManager.ayahs = []
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Retour")
                            }
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if showSearch {
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Rechercher dans le Coran", text: $searchText)
                                    .onChange(of: searchText) { newValue in
                                        if !newValue.isEmpty {
                                            performSearch()
                                        } else {
                                            searchResults = []
                                        }
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        searchResults = []
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            
                            if isSearching {
                                HStack {
                                    ProgressView()
                                    Text("Recherche en cours...")
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                            }
                            
                            Spacer()
                        }
                        .transition(.move(edge: .top))
                        .zIndex(1)
                    }
                }
            )
            .onAppear {
                if quranManager.surahs.isEmpty {
                    Task {
                        await quranManager.loadSurahs()
                    }
                }
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
                if quranManager.currentSurah != nil {
                    if let surahNumber = quranManager.currentSurah?.number {
                        Task {
                            await quranManager.loadAyahs(for: surahNumber)
                        }
                    }
                } else {
                    Task {
                        await quranManager.loadSurahs()
                    }
                }
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
    
    private var surahsListView: some View {
        List {
            ForEach(quranManager.surahs) { surah in
                Button(action: {
                    showSearch = false
                    Task {
                        await quranManager.loadAyahs(for: surah.number)
                    }
                }) {
                    HStack {
                        Text("\(surah.number)")
                            .font(.headline)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.green.opacity(0.2)))
                        
                        VStack(alignment: .leading) {
                            Text(surah.name)
                                .font(.headline)
                            
                            Text("\(surah.englishName) • \(surah.englishNameTranslation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(surah.numberOfAyahs)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(5)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var ayahsView: some View {
        List {
            if let surah = quranManager.currentSurah {
                Section(header: 
                    VStack(alignment: .center, spacing: 10) {
                        Text(surah.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(surah.englishName) - \(surah.englishNameTranslation)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(surah.numberOfAyahs) versets • \(surah.revelationType)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                ) {
                    ForEach(quranManager.ayahs) { ayah in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text("\(ayah.numberInSurah)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.green))
                                
                                Text(ayah.text)
                                    .font(.body)
                                    .lineSpacing(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var searchResultsView: some View {
        List {
            if searchResults.isEmpty && !isSearching {
                Text("Aucun résultat trouvé")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(searchResults) { ayah in
                    Button(action: {
                        Task {
                            await quranManager.loadAyahs(for: ayah.surah)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sourate \(ayah.surah)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Text("Verset \(ayah.numberInSurah)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(ayah.text)
                                .font(.body)
                                .lineSpacing(5)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func performSearch() {
        guard searchText.count >= 2 else { return }
        
        isSearching = true
        searchResults = []
        
        Task {
            let results = await quranManager.searchAyahs(query: searchText)
            DispatchQueue.main.async {
                searchResults = results
                isSearching = false
            }
        }
    }
} 