import Foundation

struct UserResponse: Codable {
    let id: UUID
    let username: String
    let email: String
    let createdAt: Date?
}

struct CreateUserRequest: Codable {
    let username: String
    let email: String
}

struct ListingResponse: Codable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let category: String
    let seller: UserResponse?
    let createdAt: Date?
}

struct CreateListingRequest: Codable {
    let title: String
    let description: String
    let price: Double
    let category: String
    let sellerID: UUID
}

struct PagedListingResponse: Codable {
    let items: [ListingResponse]
    let page: Int
    let totalPages: Int
    let totalCount: Int
}

struct ServerError: Codable {
    var reason: String?
    var error: Bool?
}

struct OfferResponse: Codable {
    let id: UUID
    let amount: Double
    let status: String
    let listingID: UUID
    let buyerID: UUID
    let buyer: UserResponse?
    let listing: ListingResponse?
    let createdAt: Date?
}

struct CreateOfferRequest: Codable {
    let amount: Double
    let buyerID: UUID
}
