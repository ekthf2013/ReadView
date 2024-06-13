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
    @IBOutlet weak var likeText: UILabel!
    @IBOutlet weak var likeButton: UIButton!

    var post: Post? // 표시할 포스트 객체

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 데이터가 존재하는지 확인하고 UI에 적용
        if let post = post {
            titleLabel.text = post.title // 제목 설정
            genreLabel.text = post.genre // 장르 설정
            authorEmailLabel.text = "작성자: \(post.email)" // 작성자 이메일 설정
            reviewContentLabel.text = post.review // 리뷰 내용 설정
            
            // 등록된 시간을 날짜 형식으로 변환하여 표시
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yy/MM/dd"
            let timestamp = dateFormatter.string(from: post.createdAt)
            timestampLabel.text = "\(timestamp)"
            
            // 책의 이미지 표시
            if let imageUrl = URL(string: post.imageURL) {
                bookImageView.sd_setImage(with: imageUrl, completed: nil)
            }
            
            // 좋아요 버튼의 초기 상태 설정
            setLikeButtonState()
        }
    }
        
    // 메뉴 버튼 클릭 시 호출되는 메소드
    @IBAction func showMenu(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "메뉴", message: nil, preferredStyle: .actionSheet)

        // 현재 로그인한 사용자의 이메일 주소 가져오기
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            return
        }

        // 포스트의 작성자 이메일과 현재 사용자의 이메일을 비교하여 팝업 메뉴에 올바른 옵션 표시
        if let postAuthorEmail = post?.email, postAuthorEmail == currentUserEmail {
            // 현재 사용자가 포스트의 작성자인 경우, "삭제하기"
            let deleteAction = UIAlertAction(title: "삭제하기", style: .destructive) { _ in
                self.deletePost()
            }
            alertController.addAction(deleteAction)
        } else {
            // 현재 사용자가 포스트의 작성자가 아닌 경우, "신고하기"
            let reportAction = UIAlertAction(title: "신고하기", style: .destructive) { _ in
                self.showAlert(message: "리뷰가 신고되었습니다.")
            }
            alertController.addAction(reportAction)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        present(alertController, animated: true, completion: nil)
    }

    // 좋아요 버튼 클릭 시 호출되는 액션 메소드
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        handleLikeButton()
    }
    
    // 포스트 삭제 메소드
    private func deletePost() {
        guard let postId = post?.id else {
            return
        }

        let db = Firestore.firestore()
        db.collection("reviews").document(postId).delete { error in
            self.showAlert(message: "리뷰가 삭제되었습니다.")
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // 좋아요 처리 메소드
    private func handleLikeButton() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            return
        }
        
        guard let postId = post?.id else {
            return
        }

        if currentUserEmail == post?.email {
            likeButton.isHidden = true
            likeText.isHidden = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("likes")
            .whereField("userEmail", isEqualTo: currentUserEmail)
            .whereField("postId", isEqualTo: postId)
            .getDocuments { (querySnapshot, error) in
                if !querySnapshot!.isEmpty {
                    self.showAlert(message: "이미 좋아요를 눌렀습니다.")
                    return
                } else {
                    let likeData = [
                        "userEmail": currentUserEmail,
                        "postId": postId,
                        "timestamp": Timestamp()
                    ] as [String : Any]
                    
                    db.collection("likes").addDocument(data: likeData) { error in
                        self.setLikeButtonState()
                        self.showAlert(message: "좋아요를 눌렀습니다.")
                    }
                }
                
            }
    }
    
    // 알림창 표시 메소드
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 좋아요 버튼 상태 설정 메소드
    private func setLikeButtonState() {
        guard let postId = post?.id else {
            likeButton.isEnabled = false
            return
        }
        
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            likeButton.isEnabled = false
            likeButton.backgroundColor = .gray
            return
        }
        
        if currentUserEmail == post?.email {
            likeButton.isHidden = true
            likeText.isHidden = true
            return
        }
        
        let db = Firestore.firestore()
        db.collection("likes")
            .whereField("userEmail", isEqualTo: currentUserEmail)
            .whereField("postId", isEqualTo: postId)
            .getDocuments { (querySnapshot, error) in
                if !querySnapshot!.isEmpty {
                    self.likeButton.tintColor = .red
                } else {
                    self.likeButton.isEnabled = true
                }
            }
    }
}
