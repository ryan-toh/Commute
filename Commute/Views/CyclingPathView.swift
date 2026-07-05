//
//  CyclingPathView.swift
//  Commute
//
//  Created by Ryan on 27/6/26.
//

import SwiftUI
import SwiftData
import MapKit

struct CyclingPathView: View {
    @StateObject var viewModel = BikeParkingLocationViewModel(
        with: BikeParkingLocationLocalDataSource(
            container: SwiftDataContextManager.shared.container,
            context: SwiftDataContextManager.shared.context
        )
    )
    
    @State private var isLoading = false
    @State var mapRegion = selectedRegion
    
    @Query var bikeParkingLocations: [BikeParkingLocation]
    
    var body: some View {
        VStack {
            VStack {
                Button("Load Data") {
                    isLoading = true
                    debugPrint("Attempting to fetch locations")

                    BikeParkingLocationViewModel.fetchBikeParkingData { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let bikeParkingLocations):
                                viewModel.addLocations(bikeParkingLocations)
                                debugPrint("Added all locations.")
                            case .failure(let error):
                                debugPrint("Attempted to add loaded locations, got: \(error)")
                            }

                            isLoading = false
                        }
                    }
                }
                .disabled(isLoading)

                if isLoading {
                    ProgressView("Loading bike parking data...")
                }
                
                Button("Clear Data") {
                    viewModel.removeAllLocations()
                    debugPrint("Cleared all locations.")
                }
            }
            .padding(20)
            
            Map {
                UserAnnotation()
                ForEach(bikeParkingLocations) { location in
                    Marker(
                        location.type,
                        coordinate: CLLocationCoordinate2D(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                    )
                }
            }
            
        }

    }
}


#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: BikeParkingLocation.self, configurations: config)
    
    CyclingPathView()
        .modelContainer(container)
}
