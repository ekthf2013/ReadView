import UIKit

class PostCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    func configure(with post: Post) {
        usernameLabel.text = post.username
        contentLabel.text = post.content
        imageView.setImage(with: URL(string: post.imageURL), completed: nil)
    }
}
