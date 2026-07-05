//
//  ContactLocalDataSource.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//


import Foundation
import SwiftData

@MainActor
class BikeParkingLocationLocalDataSource {
    private let container: ModelContainer?
    private let context: ModelContext?
    
    init(container: ModelContainer?, context: ModelContext?) {
        self.container = container
        self.context = context
    }
}

extension BikeParkingLocationLocalDataSource {
    func insert(_ entity: BikeParkingLocation) {
        self.container?.mainContext.insert(entity)
        try? self.container?.mainContext.save()
    }
    
    func insertAll(_ entities: [BikeParkingLocation]) {
        entities.forEach { entity in
            self.container?.mainContext.insert(entity)
        }
        try? self.container?.mainContext.save()
    }

    func delete(_ entity: BikeParkingLocation) {
        self.container?.mainContext.delete(entity)
        try? self.container?.mainContext.save()
    }
    
    func deleteAll() {
        try? self.container?.mainContext.delete(model: BikeParkingLocation.self)
//        try? self.container?.mainContext.delete(model: BikeParkingLocation.self)
        try? self.container?.mainContext.save()
    }
    
    func fetchBikeParkingLocations() -> [BikeParkingLocation] {
        let fetchDescriptor = FetchDescriptor<BikeParkingLocation>(sortBy: [SortDescriptor(\.type, order: .forward)])
        let locations = try? self.container?.mainContext.fetch(fetchDescriptor)
        return locations ?? []
    }
}
