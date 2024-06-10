import UIKit
import SDWebImage

class PostCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    
    func configure(with post: Post) {
        titleLabel.text = post.title
        genreLabel.text = post.genre
        if let url = URL(string: post.imageURL) {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
    }
}
