import Foundation
import ArgumentParser

struct ListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "listings", abstract: "List all listings.")
    
    @Option(name: .long, help: "Page number")
    var page: Int = 1
    
    @Option(name: .long, help: "Filter by category")
    var category: String?
    
    @Option(name: .long, help: "Search query")
    var query: String?
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            let paged = try await api.getListings(page: page, category: category, query: query)
            if paged.items.isEmpty {
                print("No listings found.")
                return
            }
            
            if paged.totalCount > paged.items.count || paged.totalPages > 1 {
                print("Listings (page \(paged.page)/\(paged.totalPages) — \(paged.totalCount) results)")
            } else {
                print("Listings (\(paged.totalCount) results)")
            }
            print(String(repeating: "─", count: 65))
            print("\(pad("ID", to: 38))\(pad("Title", to: 19))\(pad("Price", to: 10))\(pad("Category", to: 14))Seller")
            
            for listing in paged.items {
                let priceStr = String(format: "%.2f€", listing.price)
                let sellerStr = listing.seller?.username ?? "unknown"
                print("\(pad(listing.id.uuidString, to: 38))\(pad(listing.title, to: 19))\(pad(priceStr, to: 10))\(pad(listing.category, to: 14))\(sellerStr)")
            }
            print(String(repeating: "─", count: 65))
            if paged.page < paged.totalPages {
                print("Next page: swiftmarket listings --page \(paged.page + 1)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct ListingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "listing", abstract: "Get listing details.")
    
    @Argument(help: "Listing ID")
    var id: String
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: id) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            let listing = try await api.getListing(id: uuid)
            print(listing.title)
            print(String(repeating: "─", count: 41))
            let priceStr = String(format: "%.2f€", listing.price)
            print("Price:       \(priceStr)")
            print("Category:    \(listing.category)")
            print("Description: \(listing.description)")
            
            let sellerInfo = listing.seller != nil ? "\(listing.seller!.username) (\(listing.seller!.email))" : "unknown"
            print("Seller:      \(sellerInfo)")
            
            if let date = listing.createdAt {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                print("Posted:      \(formatter.string(from: date))")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct PostCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "post", abstract: "Create a new listing.")
    
    @Option(name: .long, help: "Title")
    var title: String
    
    @Option(name: .long, help: "Description")
    var desc: String
    
    @Option(name: .long, help: "Price")
    var price: Double
    
    @Option(name: .long, help: "Category")
    var category: String
    
    @Option(name: .long, help: "Seller ID")
    var seller: String
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let sellerUUID = UUID(uuidString: seller) else {
                printError("Error: Invalid seller UUID.")
                throw ExitCode.failure
            }
            let req = CreateListingRequest(title: title, description: desc, price: price, category: category, sellerID: sellerUUID)
            let listing = try await api.createListing(req)
            print("Listing created successfully.")
            print("ID:          \(listing.id.uuidString)")
            print("Title:       \(listing.title)")
            let priceStr = String(format: "%.2f€", listing.price)
            print("Price:       \(priceStr)")
            print("Category:    \(listing.category)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "delete", abstract: "Delete a listing.")
    
    @Argument(help: "Listing ID")
    var id: String
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: id) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            
            // Need to get title before deleting?
            // "Listing \"Mac mini M2\" deleted." Wait, deletion might not return the listing, we might need to fetch it first.
            let listing = try await api.getListing(id: uuid)
            try await api.deleteListing(id: uuid)
            print("Listing \"\(listing.title)\" deleted.")
            
        } catch {
            // handle error properly
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "user-listings", abstract: "Get listings for a specific user.")
    
    @Argument(help: "User ID")
    var id: String
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: id) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            let user = try await api.getUser(id: uuid)
            let listings = try await api.getUserListings(userID: uuid)
            
            print("Listings by \(user.username) (\(listings.count))")
            print(String(repeating: "─", count: 65))
            print("\(pad("ID", to: 38))\(pad("Title", to: 19))\(pad("Price", to: 10))Category")
            
            for listing in listings {
                let priceStr = String(format: "%.2f€", listing.price)
                print("\(pad(listing.id.uuidString, to: 38))\(pad(listing.title, to: 19))\(pad(priceStr, to: 10))\(listing.category)")
            }
            
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
