import UIKit
import SDWebImage

class MyPageTableViewCell: UITableViewCell {
    @IBOutlet weak var reviewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!

    func configure(with post: Post) {
        titleLabel.text = post.title
        genreLabel.text = post.genre
        if let imageURL = URL(string: post.imageURL) {
            reviewImageView.sd_setImage(with: imageURL, completed: nil)
        }
    }
}
