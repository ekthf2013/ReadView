import Foundation

struct Post: Decodable {
    let id: String
    var title: String
    var review: String
    var genre: String
    let imageURL: String
    var createdAt: Date
    let email: String
}
