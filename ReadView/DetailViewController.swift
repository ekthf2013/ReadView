import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class DetailViewController: UIViewController {

    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var authorEmailLabel: UILabel!
    @IBOutlet weak var reviewContentLabel: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton! // 좋아요 버튼 추가

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
            
            // 좋아요 버튼의 초기 상태를 설정합니다.
            setLikeButtonState()
        }
    }
    
    // 좋아요 버튼을 누른 경우 호출되는 액션 메소드
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        handleLikeButton()
    }
    
    // 좋아요 버튼 처리 메소드
    func handleLikeButton() {
        // 현재 사용자가 로그인되어 있는지 확인합니다.
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            // 사용자가 로그인되어 있지 않은 경우에는 처리를 중단하고 알림창을 띄웁니다.
            return
        }
        
        // 포스트가 존재하는지, 포스트의 ID가 있는지 확인합니다.
        guard let postId = post?.id else {
            // 포스트가 없거나 ID가 없는 경우에는 처리를 중단하고 알림창을 띄웁니다.
            return
        }

        
        // 현재 사용자가 글 작성자인지 확인합니다.
        if currentUserEmail == post?.email {
            likeButton.isHidden = true
            return
        }
        
        // Firestore에서 현재 사용자가 해당 포스트에 대해 좋아요를 이미 추가했는지 확인합니다.
        let db = Firestore.firestore()
        db.collection("likes")
            .whereField("userEmail", isEqualTo: currentUserEmail)
            .whereField("postId", isEqualTo: postId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    // 좋아요를 이미 추가한 경우에는 알림창을 띄우고 처리를 중단합니다.
                    if !querySnapshot!.isEmpty {
                        self.showAlert(message: "이미 좋아요를 눌렀습니다.")
                        return
                    } else {
                        // 좋아요 데이터를 Firestore에 추가합니다.
                        let likeData = [
                            "userEmail": currentUserEmail,
                            "postId": postId,
                            "timestamp": Timestamp() // 현재 시간을 저장
                        ] as [String : Any]
                        
                        db.collection("likes").addDocument(data: likeData) { error in
                            if let error = error {
                                print("Error adding like: \(error)")
                            } else {
                                print("Like added successfully")
                                // 좋아요 버튼의 외관을 업데이트합니다.
                                self.setLikeButtonState()
                                // 알림창을 띄웁니다.
                                self.showAlert(message: "좋아요를 눌렀습니다.")
                            }
                        }
                    }
                }
            }
    }
    
    // 알림창을 띄우는 메소드
    func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 좋아요 버튼의 외관을 업데이트하는 메소드
    func setLikeButtonState() {
        // 포스트가 존재하는지 확인합니다.
        guard let postId = post?.id else {
            // 포스트가 없는 경우에는 좋아요 버튼을 비활성화하고 회색으로 표시합니다.
            likeButton.isEnabled = false
            return
        }
        
        // 현재 사용자가 로그인되어 있는지 확인합니다.
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            // 사용자가 로그인되어 있지 않은 경우에는 좋아요 버튼을 비활성화하고 회색으로 표시합니다.
            likeButton.isEnabled = false
            likeButton.backgroundColor = .gray
            return
        }
        
        // 현재 사용자가 글 작성자인 경우에는 좋아요 버튼을 비활성화하고 회색으로 표시합니다.
        if currentUserEmail == post?.email {
            likeButton.isHidden = true
            return
        }
        
        // Firestore에서 현재 사용자가 해당 포스트에 대해 좋아요를 이미 추가했는지 확인합니다.
        let db = Firestore.firestore()
        db.collection("likes")
            .whereField("userEmail", isEqualTo: currentUserEmail)
            .whereField("postId", isEqualTo: postId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    // 좋아요를 이미 추가한 경우에는 버튼을 비활성화하고 녹색으로 표시합니다.
                    if !querySnapshot!.isEmpty {
                        self.likeButton.tintColor = .red
                    } else {
                        // 좋아요를 추가하지 않은 경우에는 버튼을 활성화하고 회색으로 표시합니다.
                        self.likeButton.isEnabled = true
                    }
                }
            }
    }

    // 알림창을 띄우는 메소드
    func showAlert() {
        let alertController = UIAlertController(title: nil, message: "저장하였습니다.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
}
