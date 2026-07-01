//
//  CyclingPathViewModel.swift
//  Commute
//
//  Created by Ryan on 30/6/26.
//

func fetchCyclingPathData() async {
    do {
        let client = DataGovSGClient(baseURLString: baseURLString)
        let datasetText = try await client.fetchDatasetText(datasetID: datasetID)
        print(datasetText)
    } catch {
        print("Error: \(error)")
    }
}
