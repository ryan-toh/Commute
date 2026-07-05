//
//  BikeParkingViewModel.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import Foundation
internal import Combine

class BikeParkingLocationViewModel: ObservableObject {
    private let dataSource: BikeParkingLocationLocalDataSource
    
    @Published var bikeParkingLocations: [BikeParkingLocation] = []
    
    init(
        with dataSource: BikeParkingLocationLocalDataSource,
    ) {
        self.dataSource = dataSource
        
        Task { @MainActor in
            bikeParkingLocations = dataSource.fetchBikeParkingLocations()
        }
    }
    
    func addLocation(_ location: BikeParkingLocation) {
        Task { @MainActor in
            dataSource.insert(location)
            syncWithModel()
        }
    }
    
    func addLocations(_ locations: [BikeParkingLocation]) {
        Task { @MainActor in
            dataSource.insertAll(locations)
            syncWithModel()
        }
    }
    
    func removeAllLocations() {
        Task { @MainActor in
            dataSource.deleteAll()
            syncWithModel()
        }
    }
    
    func syncWithModel() {
        bikeParkingLocations = dataSource.fetchBikeParkingLocations()
    }
    
    static func fetchBikeParkingData(
        completion: @escaping (Result<[BikeParkingLocation], Error>) -> Void
    ) {
        fetchBikeParkingUrl { result in
            
            switch result {
            case .success(let response):
                
                BikeParkingLocationViewModel.fetchBikeParkingJson(
                    at: response.data.url,
                ) {
                    result in
                    switch result {
                    case .success(let data):
                        completion(.success(BikeParkingLocationViewModel.convertBikeParkingJsonToModel(for: data)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func fetchBikeParkingUrl(
        completion: @escaping (Result<BikeParkingUrlModel, Error>) -> Void
    ) {
        let url = URL(
            string: "https://api-open.data.gov.sg/v1/public/api/datasets/d_937424cca6d1617288a82a7aeb89f76d/poll-download"
        )!

        URLSession.shared.fetchData(
            at: url,
            completion: completion
        )
    }

    static func fetchBikeParkingJson(
        at url: URL,
        completion: @escaping (Result<BikeParkingJsonModel, Error>) -> Void
    ) {
        URLSession.shared.fetchData(
            at: url,
            completion: completion
        )
    }

    private static func convertBikeParkingJsonToModel(for json: BikeParkingJsonModel) -> [BikeParkingLocation] {
        return json.features.map{$0.toBikeParkingLocation()}
    }
    
}
