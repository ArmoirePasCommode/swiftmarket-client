import Foundation
import ArgumentParser

struct OfferCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "offer", abstract: "Make an offer on a listing.")

    @Argument(help: "Listing ID")
    var listingID: String

    @Option(name: .long, help: "Offer amount")
    var amount: Double

    @Option(name: .long, help: "Buyer ID")
    var buyer: String

    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let listingUUID = UUID(uuidString: listingID) else {
                printError("Error: Invalid listing UUID.")
                throw ExitCode.failure
            }
            guard let buyerUUID = UUID(uuidString: buyer) else {
                printError("Error: Invalid buyer UUID.")
                throw ExitCode.failure
            }
            let req = CreateOfferRequest(amount: amount, buyerID: buyerUUID)
            let offer = try await api.offer(listingID: listingUUID, body: req)
            print("Offer sent successfully.")
            print("Listing: \(offer.listing?.title ?? listingID)")
            let amountStr = String(format: "%.2f€", offer.amount)
            print("Amount:  \(amountStr)")
            print("Status:  \(offer.status)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct OffersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "offers", abstract: "List offers on a listing.")

    @Argument(help: "Listing ID")
    var listingID: String

    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: listingID) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            let offers = try await api.offers(listingID: uuid)
            let listing = try await api.getListing(id: uuid)

            print("Offers for \"\(listing.title)\" (\(offers.count))")
            print(String(repeating: "─", count: 65))
            print("\(pad("ID", to: 38))\(pad("Buyer", to: 9))\(pad("Amount", to: 11))Status")
            for offer in offers {
                let amountStr = String(format: "%.2f€", offer.amount)
                let buyerStr = offer.buyer?.username ?? "unknown"
                print("\(pad(offer.id.uuidString, to: 38))\(pad(buyerStr, to: 9))\(pad(amountStr, to: 11))\(offer.status)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct AcceptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "accept", abstract: "Accept an offer.")

    @Argument(help: "Offer ID")
    var id: String

    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: id) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            let offer = try await api.acceptOffer(id: uuid)
            let amountStr = String(format: "%.2f€", offer.amount)
            let buyerStr = offer.buyer?.username ?? "unknown"
            let listingTitle = offer.listing?.title ?? "unknown"
            print("Offer accepted.")
            print("Listing: \(listingTitle)")
            print("Buyer:   \(buyerStr)")
            print("Amount:  \(amountStr)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct RejectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "reject", abstract: "Reject an offer.")

    @Argument(help: "Offer ID")
    var id: String

    mutating func run() async throws {
        let api = APIClient()
        do {
            guard let uuid = UUID(uuidString: id) else {
                printError("Error: Invalid UUID.")
                throw ExitCode.failure
            }
            let offer = try await api.rejectOffer(id: uuid)
            let buyerStr = offer.buyer?.username ?? "unknown"
            print("Offer from \(buyerStr) rejected.")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
