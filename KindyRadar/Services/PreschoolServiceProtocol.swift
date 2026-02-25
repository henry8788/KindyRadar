import Foundation

protocol PreschoolServiceProtocol {
    func fetchPreschools() async throws -> [Preschool]
}
