import Foundation

enum FlightServiceError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Supabase URL is invalid."
        case .requestFailed(let code):
            return "Request failed with status code \(code)."
        case .emptyResponse:
            return "Server returned an empty response."
        }
    }
}

struct NewFlightPayload: Encodable {
    let airline: String
    let flight_number: String
    let date: String
    let from_airport_code: String
    let to_airport_code: String
    let trip_type: String
}

final class FlightService {
    private var baseURL: String {
        SupabaseConfig.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func flightsURL(query: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)/rest/v1/FlightsA?\(query)") else {
            throw FlightServiceError.invalidURL
        }
        return url
    }

    func fetchFlights(limit: Int = 500) async throws -> [Flight] {
        let url = try flightsURL(query: "select=*&order=date.desc&limit=\(limit)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FlightServiceError.requestFailed(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Flight].self, from: data)
    }

    func insertFlight(_ payload: NewFlightPayload) async throws {
        let url = try flightsURL(query: "select=flight_id")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FlightServiceError.requestFailed(httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw FlightServiceError.emptyResponse
        }
    }
}