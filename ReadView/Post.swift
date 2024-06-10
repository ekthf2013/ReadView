import Foundation

struct Post: Decodable {
    let id: String
    let title: String
    let review: String
    let genre: String
    let imageURL: String
    let createdAt: Date
    let email: String
}
