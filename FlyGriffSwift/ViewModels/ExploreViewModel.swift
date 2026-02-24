import Foundation

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    private let service = FlightService()

    func loadFlights() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            flights = try await service.fetchFlights()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}