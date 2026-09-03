//
//  CyclingPathSegmentEditorView.swift
//  Commute
//
//  Created by Ryan on 1/9/26.
//

import CoreLocation
import MapKit
import SwiftUI
// EXTREMELY UGLY FOR DEV PURPOSES

/// A deliberately self-contained development tool for drawing and uploading cycling paths.
/// The upload secret is held only for the lifetime of this view.
struct CyclingPathSegmentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CyclingPathRepository.self) private var cyclingPathRepository

    @State private var coordinates: [LocationCoordinate] = []
    @State private var pathName = ""
    @State private var uploadSecret = ""
    @State private var publishesSnapshot = true
    @State private var isUploading = false
    @State private var isFetchingDatabase = false
    @State private var statusMessage: String?
    @State private var isShowingError = false
    @State private var isShowingDeleteDatabaseConfirmation = false
    @State private var errorTitle = Preferences.DevTools.routeEditorUploadFailedMessage
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: Preferences.DevTools.routeEditorInitialLatitude,
                longitude: Preferences.DevTools.routeEditorInitialLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: Preferences.DevTools.routeEditorInitialLatitudeDelta,
                longitudeDelta: Preferences.DevTools.routeEditorInitialLongitudeDelta
            )
        )
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if coordinates.count >= 2 {
                            MapPolyline(coordinates: coordinates.map(mapCoordinate(from:)))
                                .stroke(
                                    Preferences.DevTools.routeEditorMapLineColor,
                                    lineWidth: Preferences.DevTools.routeEditorMapLineWidth
                                )
                        }

                        if let first = coordinates.first {
                            Marker("Start", coordinate: mapCoordinate(from: first))
                                .tint(.green)
                        }

                        if coordinates.count > 1, let last = coordinates.last {
                            Marker("End", coordinate: mapCoordinate(from: last))
                                .tint(.red)
                        }
                    }
                    .simultaneousGesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard let coordinate = proxy.convert(value.location, from: .local) else {
                                    return
                                }
                                coordinates.append(
                                    LocationCoordinate(
                                        latitude: coordinate.latitude,
                                        longitude: coordinate.longitude
                                    )
                                )
                            }
                    )
                }
                .frame(maxHeight: .infinity)

                Form {
                    Section {
                        Text(Preferences.DevTools.routeEditorInstructions)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(String(format: Preferences.DevTools.routeEditorPointCountFormat, coordinates.count))
                    }

                    Section {
                        TextField(Preferences.DevTools.routeEditorNamePrompt, text: $pathName)
                        SecureField(Preferences.DevTools.routeEditorSecretPrompt, text: $uploadSecret)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Toggle(Preferences.DevTools.routeEditorPublishTitle, isOn: $publishesSnapshot)
                    }

                    Section {
                        HStack {
                            Button(Preferences.DevTools.routeEditorUndoTitle) {
                                _ = coordinates.popLast()
                            }
                            .disabled(coordinates.isEmpty || isUploading)

                            Spacer()

                            Button(Preferences.DevTools.routeEditorClearTitle, role: .destructive) {
                                coordinates.removeAll()
                            }
                            .disabled(coordinates.isEmpty || isUploading)
                        }

                        Button {
                            Task { await uploadSegment() }
                        } label: {
                            if isUploading {
                                HStack {
                                    ProgressView()
                                    Text(Preferences.DevTools.routeEditorUploadingTitle)
                                }
                            } else {
                                Text(Preferences.DevTools.routeEditorUploadTitle)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(!canUpload)
                    }

                    Section {
                        Button {
                            Task { await fetchLatestCombinedDatabase() }
                        } label: {
                            if isFetchingDatabase {
                                HStack {
                                    ProgressView()
                                    Text(Preferences.DevTools.routeEditorFetchingDatabaseTitle)
                                }
                            } else {
                                Text(Preferences.DevTools.routeEditorFetchDatabaseTitle)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isUploading || isFetchingDatabase)

                        Button(
                            Preferences.DevTools.routeEditorDeleteDatabaseTitle,
                            role: .destructive
                        ) {
                            isShowingDeleteDatabaseConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isUploading || isFetchingDatabase)
                    }
                }
                .frame(height: Preferences.DevTools.routeEditorSheetHeight / 2)
            }
            .navigationTitle(Preferences.DevTools.routeEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(
                errorTitle,
                isPresented: $isShowingError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage ?? Preferences.DevTools.routeEditorUploadFailedMessage)
            }
            .confirmationDialog(
                Preferences.DevTools.routeEditorDeleteDatabaseConfirmationTitle,
                isPresented: $isShowingDeleteDatabaseConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    Preferences.DevTools.routeEditorDeleteDatabaseActionTitle,
                    role: .destructive
                ) {
                    deleteLocalDatabase()
                }
            } message: {
                Text(Preferences.DevTools.routeEditorDeleteDatabaseConfirmationMessage)
            }
            .overlay(alignment: .top) {
                if let statusMessage, !isShowingError {
                    Text(statusMessage)
                        .font(.footnote.weight(.medium))
                        .padding(10)
                        .background(.regularMaterial, in: Capsule())
                        .padding()
                }
            }
        }
    }

    private var canUpload: Bool {
        coordinates.count >= 2 && !uploadSecret.isEmpty && !isUploading
    }

    private func uploadSegment() async {
        guard coordinates.count >= 2 else {
            presentError(Preferences.DevTools.routeEditorMinimumPointMessage)
            return
        }
        guard !uploadSecret.isEmpty else {
            presentError(Preferences.DevTools.routeEditorMissingSecretMessage)
            return
        }

        isUploading = true
        statusMessage = nil
        defer { isUploading = false }

        do {
            let endpoint = try uploadEndpoint()
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(uploadSecret)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(
                UploadRequest(
                    segment: CyclingPathSegment(
                        id: UUID().uuidString,
                        name: pathName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                        lengthMeters: nil,
                        coordinates: coordinates
                    )
                )
            )

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8)
                throw UploadError.server(serverMessage)
            }

            coordinates.removeAll()
            pathName = ""
            statusMessage = Preferences.DevTools.routeEditorUploadSucceededMessage
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func uploadEndpoint() throws -> URL {
        var components = URLComponents(
            url: Preferences.CyclingPaths.cloudflareR2Endpoint,
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = publishesSnapshot
            ? [URLQueryItem(name: "publish", value: "true")]
            : []

        guard let url = components?.url else {
            throw UploadError.invalidEndpoint
        }
        return url
    }

    private func fetchLatestCombinedDatabase() async {
        isFetchingDatabase = true
        statusMessage = nil
        defer { isFetchingDatabase = false }

        do {
            let didRefresh = try await cyclingPathRepository.refreshNow()
            statusMessage = didRefresh
                ? Preferences.DevTools.routeEditorFetchDatabaseSucceededMessage
                : Preferences.DevTools.routeEditorFetchDatabaseInProgressMessage
        } catch {
            presentError(
                error.localizedDescription,
                title: Preferences.DevTools.routeEditorFetchDatabaseFailedMessage
            )
        }
    }

    private func deleteLocalDatabase() {
        do {
            let didDelete = try cyclingPathRepository.deleteLocalSegments()
            statusMessage = didDelete
                ? Preferences.DevTools.routeEditorDeleteDatabaseSucceededMessage
                : Preferences.DevTools.routeEditorDeleteDatabaseInProgressMessage
        } catch {
            presentError(
                error.localizedDescription,
                title: Preferences.DevTools.routeEditorDeleteDatabaseTitle
            )
        }
    }

    private func presentError(
        _ message: String,
        title: String = Preferences.DevTools.routeEditorUploadFailedMessage
    ) {
        errorTitle = title
        statusMessage = message
        isShowingError = true
    }

    private func mapCoordinate(from coordinate: LocationCoordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

private struct UploadRequest: Encodable {
    let segment: CyclingPathSegment
}

private enum UploadError: LocalizedError {
    case invalidEndpoint
    case server(String?)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            "The cycling path upload endpoint is invalid."
        case let .server(message):
            message?.nilIfEmpty ?? "The cycling path service rejected the upload."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
