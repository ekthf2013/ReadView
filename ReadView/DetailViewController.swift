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
    
    @IBAction func showMenu(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "메뉴", message: nil, preferredStyle: .actionSheet)
        
        // 현재 로그인한 사용자의 이메일 주소 가져오기
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            // 사용자가 로그인하지 않은 경우, 여기에서 로그인 화면을 표시하거나 다른 처리를 할 수 있습니다.
            return
        }
        
        // 포스트의 작성자 이메일과 현재 사용자의 이메일을 비교하여 팝업 메뉴에 올바른 옵션을 표시합니다.
        if let postAuthorEmail = post?.email, postAuthorEmail == currentUserEmail {
            // 현재 사용자가 포스트의 작성자인 경우, "삭제하기" 메뉴를 추가합니다.
            let deleteAction = UIAlertAction(title: "삭제하기", style: .destructive) { _ in
                // 포스트를 삭제하는 로직을 구현합니다.
                self.deletePost()
            }
            alertController.addAction(deleteAction)
        } else {
            // 현재 사용자가 포스트의 작성자가 아닌 경우, "신고하기" 메뉴를 추가합니다.
            let reportAction = UIAlertAction(title: "신고하기", style: .destructive) { _ in
                self.showAlert()
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
    private func showAlert(){
        let alertController = UIAlertController(title: "알림", message: "접수하였습니다.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
    }
    // 포스트를 삭제하는 함수
    func deletePost() {
        guard let postId = post?.id else {
            print("Post ID is missing")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("reviews").document(postId).delete { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
                // 삭제 성공 시 알림 표시
                self.showDeleteSuccessAlert()
            }
        }
    }


    
    // 삭제 성공 알림 표시 함수
    func showDeleteSuccessAlert() {
        let alertController = UIAlertController(title: "알림", message: "리뷰가 삭제되었습니다.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "확인", style: .default) { _ in
            // 확인 버튼을 누를 때 홈 화면으로 이동
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
}
