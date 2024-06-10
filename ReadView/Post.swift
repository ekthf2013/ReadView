import Foundation

struct Post: Decodable {
    let title: String
    let review: String
    let genre: String
    let imageURL: String
    let createdAt: Date
    let email: String
}
