

import Foundation

struct CyclingPathBridges {
    let approachRoute: Route
    let departureRoute: Route
}

@MainActor
protocol CyclingPathBridgePlanning {
    func planBridges(
        from origin: Location,
        through excursion: CyclingPathExcursion,
        to destination: Location
    ) async throws -> CyclingPathBridges
}

@MainActor
struct RoutePlanningCyclingPathBridgePlanner: CyclingPathBridgePlanning {
    let routePlanningService: any RoutePlanningService

    func planBridges(
        from origin: Location,
        through excursion: CyclingPathExcursion,
        to destination: Location
    ) async throws -> CyclingPathBridges {
        let cyclingPathEntry = makeLocation(
            at: excursion.entryCoordinate,
            named: Preferences.RoutePlanning.cyclingPathEntryName
        )
        let cyclingPathExit = makeLocation(
            at: excursion.exitCoordinate,
            named: Preferences.RoutePlanning.cyclingPathExitName
        )

        async let approachRoute = routePlanningService.planCyclingRoute(
            from: origin,
            to: cyclingPathEntry
        )
        async let departureRoute = routePlanningService.planCyclingRoute(
            from: cyclingPathExit,
            to: destination
        )

        return try await CyclingPathBridges(
            approachRoute: approachRoute,
            departureRoute: departureRoute
        )
    }

    private func makeLocation(
        at coordinate: LocationCoordinate,
        named name: String
    ) -> Location {
        Location(
            id: UUID(),
            coordinate: coordinate,
            address: nil,
            name: name,
            source: .unknown,
            capturedAt: .now
        )
    }
}
