import Foundation
import ArgumentParser

func pad(_ string: String, to length: Int) -> String {
    if string.count < length {
        return string + String(repeating: " ", count: length - string.count)
    }
    return string
}

struct CreateUserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "create-user", abstract: "Create a new user.")
    
    @Option(name: .long, help: "Username")
    var username: String
    
    @Option(name: .long, help: "Email address")
    var email: String
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            let req = CreateUserRequest(username: username, email: email)
            let res = try await api.createUser(req)
            print("User created successfully.")
            print("ID:       \(res.id.uuidString)")
            print("Username: \(res.username)")
            print("Email:    \(res.email)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "users", abstract: "List all users.")
    
    mutating func run() async throws {
        let api = APIClient()
        do {
            let users = try await api.getUsers()
            print("Users (\(users.count))")
            print(String(repeating: "─", count: 65))
            print("\(pad("ID", to: 38))\(pad("Username", to: 11))Email")
            for user in users {
                print("\(pad(user.id.uuidString, to: 38))\(pad(user.username, to: 11))\(user.email)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "user", abstract: "Get user details.")
    
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
            print(user.username)
            print("Email:        \(user.email)")
            
            if let date = user.createdAt {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                print("Member since: \(formatter.string(from: date))")
            } else {
                // Ignore if unknown or just print unknown if the instructions imply it, wait instructions say: Member since: 2024-03-15 or Error: User not found.
                // Assuming createdAt is returned.
                print("Member since: unknown")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
