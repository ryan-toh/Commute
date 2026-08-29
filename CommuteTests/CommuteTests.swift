//
//  CommuteTests.swift
//  CommuteTests
//
//  Created by Ryan on 26/6/26.
//

import Foundation
import Testing
@testable import Commute

struct CommuteTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func progressShowsFollowingManeuverBeforeTheCurrentManeuver() {
        let route = Route(
            id: UUID(),
            coordinates: [
                LocationCoordinate(latitude: 1, longitude: 103),
                LocationCoordinate(latitude: 1, longitude: 103.001),
                LocationCoordinate(latitude: 1, longitude: 103.002)
            ],
            steps: [
                step(at: 1),
                step(at: 2)
            ],
            distanceMeters: 222,
            expectedTravelTime: 60,
            transportMode: .cycling
        )

        let calculator = RouteProgressCalculator()
        let beforeTurn = calculator.progress(on: route, at: location(longitude: 103), after: nil)
        let approachingTurn = calculator.progress(on: route, at: location(longitude: 103.0009), after: nil)

        #expect(beforeTurn?.nextStepIndex == 0)
        #expect(approachingTurn?.nextStepIndex == 1)
        #expect((approachingTurn?.distanceToNextStepMeters ?? 0) > 25)
    }

    private func step(at routeCoordinateIndex: Int) -> RouteStep {
        RouteStep(
            id: UUID(),
            instruction: "Continue",
            maneuver: .straight,
            distanceMeters: 100,
            coordinate: LocationCoordinate(latitude: 1, longitude: 103),
            routeCoordinateIndex: routeCoordinateIndex,
            transportMode: .cycling,
            source: .curatedPath
        )
    }

    private func location(longitude: Double) -> Location {
        Location(
            id: UUID(),
            coordinate: LocationCoordinate(latitude: 1, longitude: longitude),
            address: nil,
            name: nil,
            source: .gps,
            capturedAt: .now
        )
    }

}
