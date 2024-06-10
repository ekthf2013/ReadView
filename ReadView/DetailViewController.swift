import UIKit
import FirebaseFirestore
import FirebaseStorage

class DetailViewController: UIViewController {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var authorEmailLabel: UILabel!
    @IBOutlet weak var reviewContentLabel: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!

    var post: Post?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 데이터가 존재하는지 확인하고 UI에 적용합니다.
        if let post = post {
            titleLabel.text = post.title
            genreLabel.text = post.genre
            // 작성자 이메일을 가져와서 라벨에 표시합니다.
            authorEmailLabel.text = "작성자: \(post.email)"
            reviewContentLabel.text = post.review
            
            // 등록된 시간을 날짜 형식으로 변환하여 표시합니다.
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yy/MM/dd HH:mm"
            let timestamp = dateFormatter.string(from: post.createdAt)
            timestampLabel.text = "등록 시간: \(timestamp)"
            
            // 책의 이미지를 표시합니다. SDWebImage 등을 사용하여 원격 이미지를 가져올 수 있습니다.
            if let imageUrl = URL(string: post.imageURL) {
                bookImageView.sd_setImage(with: imageUrl, completed: nil)
            }
        }
    }
}
