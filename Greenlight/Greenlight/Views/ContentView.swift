//
//  ContentView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Persistent Storage
    
    @AppStorage("savedCity") private var savedCityData: String = ""
    @AppStorage("savedCities") private var savedCitiesData: String = "[]"

    // MARK: - Search State
    
    @State private var query: String = ""
    @State private var cities: [City] = []
    
    // MARK: - UI State
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // debounce: cancel the previous scheduled search when user keeps typing
    @State private var searchTask: Task<Void, Never>? = nil
    
    // MARK: - Derived State
    
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    // decode saved city once for "Continue"
    private var lastCity: City? { loadLastCity() }
    
    // decode saved cities list once for "Saved Cities"
    private var savedCities: [City] { loadSavedCities() }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            searchUI
        }
    }
    
    // MARK: - Search UI
    
    private var searchUI: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
                // help text
                HStack {
                    Text("Find a city, then get a ")
                        .foregroundStyle(.secondary)
                    + Text("go")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                    + Text(" / ")
                        .foregroundStyle(.secondary)
                    + Text("caution")
                        .foregroundStyle(Color.orange.opacity(0.75))
                        .fontWeight(.semibold)
                    + Text(" / ")
                        .foregroundStyle(.secondary)
                    + Text("stop")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.horizontal)

                // search field
                TextField("Search for a city", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.separator).opacity(0.25))
                    )
                    .padding(.top, 8)
                    .padding(.horizontal)
                
                // loading spinner
                if isLoading {
                    HStack{ Spacer(); ProgressView().tint(.secondary); Spacer() }
                }
                
                // error message (user-facing)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
                
                
                List {
                    // continue (only when not actively searching)
                    if let lastCity, trimmedQuery.isEmpty {
                        Section(header: Text("Continue").font(.footnote)) {
                            NavigationLink {
                                ForecastView(city: lastCity, onChangeCity: nil)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(lastCity.name), \(lastCity.admin1 ?? lastCity.country)")
                                            .lineLimit(1)
                                        Text("Last viewed")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { savedCityData = "" } label: {
                                    Label("Clear", systemImage: "xmark")
                                }
                            }
                        }
                        .textCase(nil)
                    }
                    
                    // saved cities
                    if !savedCities.isEmpty {
                        Section(header: Text("Saved Cities").font(.footnote)) {
                            ForEach(savedCities, id: \.id) { city in
                                NavigationLink {
                                    ForecastView(city: city, onChangeCity: nil)
                                } label: {
                                    cityRow(city)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removeSavedCity(city)
                                    } label: {
                                        Label("Remove", systemImage: "pin.slash")
                                    }
                                }
                            }
                        }
                        .textCase(nil)
                    }
                    
                    // results list (only when user typed something)
                    if !trimmedQuery.isEmpty {
                        Section(header: Text("Results").font(.footnote)) {
                            ForEach(cities, id: \.id) { city in
                                NavigationLink {
                                    ForecastView(city: city, onChangeCity: nil)
                                } label: {
                                    cityRow(city)
                                }
                            }
                        }
                        .textCase(nil)
                    }
                }
                .scrollContentBackground(.hidden)
                .animation(.easeInOut(duration: 0.2), value: cities)
            }
        }
        .navigationTitle("City Search")
        .onChange(of: query) { _, newValue in
            scheduleSearch(newValue)
        }
    }
    
    // MARK: - Row UI
    
    @ViewBuilder
    private func cityRow(_ city: City) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(city.name), \(city.admin1 ?? city.country)")
                    .lineLimit(1)

                Text(city.country_code ?? city.country)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
        
    // MARK: - Persistence Helpers
    
    private func loadLastCity() -> City? {
        guard let data = savedCityData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(City.self, from: data)
        else { return nil }
        return decoded
    }
        
    private func loadSavedCities() -> [City] {
        guard let data = savedCitiesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([City].self, from: data)
        else { return [] }
        return decoded
    }

    private func saveSavedCities(_ cities: [City]) {
        guard let data = try? JSONEncoder().encode(cities),
              let string = String(data: data, encoding: .utf8)
        else { return }
        savedCitiesData = string
    }
    
    private func removeSavedCity(_ city: City) {
        var updated = loadSavedCities()
        updated.removeAll { $0.id == city.id }
        saveSavedCities(updated)
    }
    
    // MARK: - Search Logic
    
    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // reset UI if the search box is empty
        if trimmed.isEmpty {
            cities = []
            errorMessage = nil
            isLoading = false
            return
        }
        
        cities = []
        errorMessage = nil
        
        // debounce: wait a bit before hitting the API
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35s
            if Task.isCancelled { return }
            await runSearch(trimmed)
        }
    }

    private func runSearch(_ trimmed: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let results = try await searchCities(query: trimmed, count: 25)
            if Task.isCancelled { return }
            
            // normalize once (for comparisons)
            let q = trimmed.lowercased()
            
            // keep prefix matches only
            let prefixFiltered = results.filter { $0.name.lowercased().hasPrefix(q) }
            
            // deduplicate by id
            var seen = Set<Int>()
            let deduped = prefixFiltered.filter { seen.insert($0.id).inserted }

            // sort: exact name > population > name
            let sorted = deduped.sorted {
                let aExact = $0.name.lowercased() == q
                let bExact = $1.name.lowercased() == q
                if aExact != bExact { return aExact && !bExact }

                let aPop = $0.population ?? -1
                let bPop = $1.population ?? -1
                if aPop != bPop { return aPop > bPop }

                return $0.name < $1.name
            }
            
            await MainActor.run {
                cities = sorted
                errorMessage = sorted.isEmpty ? "No results." : nil
                isLoading = false
            }
            
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                cities = []
                errorMessage = "Couldn't load results. Try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
