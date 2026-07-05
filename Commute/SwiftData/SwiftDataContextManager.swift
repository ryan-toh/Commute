//
//  SwiftDataContextManager.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//


import Foundation
import SwiftData

class SwiftDataContextManager{
    // Singleton
    static let shared = SwiftDataContextManager()
    
    var container: ModelContainer?
    var context : ModelContext?
    
    private init() {
        do {
            container = try ModelContainer(for: BikeParkingLocation.self)
            if let container {
                context = ModelContext(container)
                prepopulateBikeParkingLocations()
            }
        } catch {
            debugPrint("Error initializing database container:", error)
        }
    }
}

fileprivate extension SwiftDataContextManager {
    private func prepopulateBikeParkingLocations() {
        guard let context = context else { return }
        
        let fetchDescriptior = FetchDescriptor<BikeParkingLocation>()
        guard let entities = try? context.fetch(fetchDescriptior) else { return }
        
        // On first init, preload LTA bike parking data
        if entities.isEmpty {
            BikeParkingLocationViewModel.fetchBikeParkingData { data in
                switch data {
                case .success(let locations):
                    locations.forEach { location in
                        context.insert(location)
                    }
                    try? context.save()
                    debugPrint("Preload LTA bike parking data succeeded")
                case .failure(let error):
                    debugPrint("Tried to preload locations, got error: \(error)")
                }
            }
            try? context.save()
        }
    }
}
