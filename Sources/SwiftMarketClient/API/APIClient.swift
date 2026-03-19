import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct APIClient {
    let baseURL: String = "http://localhost:8080"
    
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
    
    private var encoder: JSONEncoder {
        return JSONEncoder()
    }
    
    private func handleHTTPResponse(_ response: URLResponse, _ data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.connectionFailed
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            let error = try? decoder.decode(ServerError.self, from: data)
            throw APIError.notFound(error?.reason ?? "Not found")
        case 409:
            let error = try? decoder.decode(ServerError.self, from: data)
            throw APIError.conflict(error?.reason ?? "Conflict")
        case 422: // Validation failed
            let error = try? decoder.decode(ServerError.self, from: data)
            throw APIError.validationFailed(error?.reason ?? "Validation failed.")
        case 500...599:
            let error = try? decoder.decode(ServerError.self, from: data)
            throw APIError.serverError(error?.reason ?? "Server error")
        default:
            let error = try? decoder.decode(ServerError.self, from: data)
            throw APIError.serverError(error?.reason ?? "Unknown error (status \(httpResponse.statusCode))")
        }
    }
    
    private func deleteRequest(path: String) async throws {
        guard let url = URL(string: baseURL + path) else { throw APIError.connectionFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let data: Data
        let response: URLResponse
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
            response = result.1
        } catch {
            throw APIError.connectionFailed
        }
        
        try handleHTTPResponse(response, data)
    }
    
    private func get<T: Codable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + path) else { throw APIError.connectionFailed }
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        guard let url = urlComponents.url else { throw APIError.connectionFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let data: Data
        let response: URLResponse
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
            response = result.1
        } catch {
            throw APIError.connectionFailed
        }
        
        try handleHTTPResponse(response, data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func put<T: Codable>(path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.connectionFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let data: Data
        let response: URLResponse
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
            response = result.1
        } catch {
            throw APIError.connectionFailed
        }
        
        try handleHTTPResponse(response, data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func post<B: Codable, T: Codable>(path: String, body: B) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.connectionFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        let data: Data
        let response: URLResponse
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
            response = result.1
        } catch {
            throw APIError.connectionFailed
        }
        
        try handleHTTPResponse(response, data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // Commands
    
    func createUser(_ body: CreateUserRequest) async throws -> UserResponse {
        return try await post(path: "/users", body: body)
    }
    
    func getUsers() async throws -> [UserResponse] {
        return try await get(path: "/users")
    }
    
    func getUser(id: UUID) async throws -> UserResponse {
        return try await get(path: "/users/\(id.uuidString)")
    }
    
    func getUserListings(userID: UUID) async throws -> [ListingResponse] {
        return try await get(path: "/users/\(userID.uuidString)/listings")
    }
    
    func createListing(_ body: CreateListingRequest) async throws -> ListingResponse {
        return try await post(path: "/listings", body: body)
    }
    
    func getListings(page: Int, category: String?, query: String?) async throws -> PagedListingResponse {
        var params: [URLQueryItem] = []
        if page > 1 {
            params.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        if let c = category, !c.isEmpty {
            params.append(URLQueryItem(name: "category", value: c))
        }
        if let q = query, !q.isEmpty {
            params.append(URLQueryItem(name: "q", value: q))
        }
        return try await get(path: "/listings", queryItems: params)
    }
    
    func getListing(id: UUID) async throws -> ListingResponse {
        return try await get(path: "/listings/\(id.uuidString)")
    }
    
    func deleteListing(id: UUID) async throws {
        return try await deleteRequest(path: "/listings/\(id.uuidString)")
    }
    
    func offer(listingID: UUID, body: CreateOfferRequest) async throws -> OfferResponse {
        return try await post(path: "/listings/\(listingID.uuidString)/offers", body: body)
    }
    
    func offers(listingID: UUID) async throws -> [OfferResponse] {
        return try await get(path: "/listings/\(listingID.uuidString)/offers")
    }
    
    func acceptOffer(id: UUID) async throws -> OfferResponse {
        return try await put(path: "/offers/\(id.uuidString)/accept")
    }
    
    func rejectOffer(id: UUID) async throws -> OfferResponse {
        return try await put(path: "/offers/\(id.uuidString)/reject")
    }
}
