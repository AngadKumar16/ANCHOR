import Foundation
import Combine

public class AuthManager: ObservableObject {
    // Singleton instance
    public static let shared = AuthManager()
    
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var currentUser: User?
    
    public struct User: Identifiable, Equatable {
        public let id: String
        public let email: String
        public let name: String?
        
        public init(id: String, email: String, name: String?) {
            self.id = id
            self.email = email
            self.name = name
        }
    }
    
    // Private initializer to enforce singleton
    private init() {
        // Check for existing session on init
        // In a real app, you would load this from secure storage
        self.isAuthenticated = false
    }
    
    // MARK: - Preview Support
    
    #if DEBUG
    /// Updates the authentication state for preview purposes only
    /// - Parameters:
    ///   - isAuthenticated: The desired authentication state
    ///   - user: Optional user to set as current user
    public func updateForPreview(isAuthenticated: Bool, user: User? = nil) {
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = isAuthenticated
        }
    }
    #endif
    
    // MARK: - Authentication Methods
    
    public func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // In a real app, this would make a network request to your auth service
        // For now, we'll simulate a successful login
        let user = User(id: UUID().uuidString, email: email, name: email.components(separatedBy: "@").first)
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
            completion(.success(user))
        }
    }
    
    public func signUp(email: String, password: String, name: String? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        // In a real app, this would make a network request to your auth service
        // For now, we'll simulate a successful signup
        let user = User(id: UUID().uuidString, email: email, name: name)
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
            completion(.success(user))
        }
    }
    
    public func signOut() {
        // In a real app, you would also clear any auth tokens from secure storage
        currentUser = nil
        isAuthenticated = false
    }
    
    public func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // In a real app, this would trigger a password reset email
        DispatchQueue.main.async {
            // Simulate network delay
            completion(.success(()))
        }
    }
}
