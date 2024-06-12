import UIKit
import FirebaseFirestore
import FirebaseAuth

class LikedPostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var likedPosts: [Post] = [] // 좋아요한 포스트를 저장할 배열
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 테이블 뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        
        // 커스텀 셀 등록
        let nib = UINib(nibName: "LikedPostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "LikedPostCell")
        
        // 좋아요한 포스트 불러오기
        fetchLikedPosts()
    }
    
    // Firestore에서 사용자가 좋아요한 포스트를 가져오는 메소드
    func fetchLikedPosts() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        let db = Firestore.firestore()
        let query = db.collection("likes")
            .whereField("userEmail", isEqualTo: userEmail)
        
        query.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.likedPosts = []
                for document in querySnapshot!.documents {
                    let postId = document["postId"] as! String
                    // 해당 postId에 해당하는 포스트를 불러와서 likedPosts 배열에 추가합니다.
                    db.collection("reviews").document(postId).getDocument { (document, error) in
                        if let document = document, document.exists {
                            if let post = try? document.data(as: Post.self) {
                                self.likedPosts.append(post)
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = likedPosts[indexPath.row]

        // DetailViewController에 선택한 포스트를 전달합니다.
        if let detailVC = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
            detailVC.post = selectedPost
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // UITableViewDataSource 메소드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likedPosts.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "내가 좋아요 누른 리뷰"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LikedPostCell", for: indexPath) as? LikedPostTableViewCell else {
            return UITableViewCell()
        }
        let post = likedPosts[indexPath.row]
        // 셀에 포스트 정보를 표시합니다.
        cell.titleLabel.text = post.title
        cell.genreLabel.text = post.genre
        if let imageURL = URL(string: post.imageURL) {
            cell.postImageView.sd_setImage(with: imageURL, completed: nil)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 해당 셀의 데이터를 삭제합니다.
            let post = likedPosts[indexPath.row]
            
            // 파이어베이스에서 해당 포스트에 대한 좋아요 데이터를 삭제합니다.
            guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
            let db = Firestore.firestore()
            db.collection("likes")
                .whereField("userEmail", isEqualTo: currentUserEmail)
                .whereField("postId", isEqualTo: post.id)
                .getDocuments { [weak self] (querySnapshot, error) in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            db.collection("likes").document(document.documentID).delete { error in
                                if let error = error {
                                    print("Error deleting document: \(error)")
                                } else {
                                    print("Document successfully deleted!")
                                    // 배열에서도 해당 포스트 데이터를 삭제합니다.
                                    if let index = self.likedPosts.firstIndex(where: { $0.id == post.id }) {
                                        self.likedPosts.remove(at: index)
                                        // 테이블 뷰에서 해당 행을 삭제합니다.
                                        tableView.deleteRows(at: [indexPath], with: .fade)
                                        tableView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 원하는 셀 높이로 설정합니다.
    }
}
