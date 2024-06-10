import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage // 이미지 로딩을 위한 라이브러리

class MyPageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var reviews: [Post] = [] // 사용자가 작성한 리뷰를 저장할 배열
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 테이블 뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        
        // 커스텀 셀 등록
        let nib = UINib(nibName: "MyPageTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ReviewCell")
        
        // 현재 사용자의 이메일을 가져와서 라벨에 표시
        if let userEmail = Auth.auth().currentUser?.email {
            emailLabel.text = userEmail
        }
        
        // 사용자가 작성한 리뷰 불러오기
        fetchUserReviews()
    }
    
    // 로그아웃 버튼 클릭 시 호출되는 메소드
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            tabBarController?.tabBar.isHidden = true
            
            // 로그아웃 성공 시 로그인 화면으로 이동 (로그인 화면이 루트 뷰 컨트롤러라고 가정)
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                self.navigationController?.setViewControllers([loginVC], animated: true)
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    // Firestore에서 사용자가 작성한 리뷰를 가져오는 메소드
    func fetchUserReviews() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    self.reviews = querySnapshot?.documents.compactMap { document -> Post? in
                        try? document.data(as: Post.self)
                    } ?? []
                    self.tableView.reloadData()
                }
            }
    }
    
    // UITableViewDataSource 메소드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as? MyPageTableViewCell else {
            return UITableViewCell()
        }
        let review = reviews[indexPath.row]
        cell.titleLabel.text = review.title
        cell.genreLabel.text = review.genre
        if let imageURL = URL(string: review.imageURL) {
            cell.reviewImageView.sd_setImage(with: imageURL, completed: nil)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 원하는 셀 높이로 설정합니다.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 선택된 셀에 해당하는 리뷰를 가져옵니다.
        let selectedReview = reviews[indexPath.row]
        
        // ReviewViewController를 가져옵니다.
        if let reviewVC = storyboard?.instantiateViewController(withIdentifier: "ReviewViewController") as? ReviewViewController {
            // ReviewViewController에 선택된 리뷰를 설정합니다.
            reviewVC.selectedReview = selectedReview
            
            // 리뷰의 이미지를 비동기적으로 가져와서 전달합니다.
            if let imageURL = URL(string: selectedReview.imageURL) {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    guard let data = data, error == nil else {
                        print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        print("Image loaded successfully: \(image ?? nil)")
                        reviewVC.reviewImage = image
                        self.navigationController?.pushViewController(reviewVC, animated: true)
                    }
                }.resume()
            } else {
                navigationController?.pushViewController(reviewVC, animated: true)
            }
        }
    }


    
    // UITableViewDelegate 메소드
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 해당 셀의 데이터를 삭제합니다.
            let review = reviews[indexPath.row]
            
            // 파이어베이스에서 해당 리뷰 데이터를 삭제합니다.
            let db = Firestore.firestore()
            db.collection("reviews").document(review.id).delete { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error deleting document: \(error)")
                } else {
                    print("Document successfully deleted!")
                    // 배열에서도 해당 리뷰 데이터를 삭제합니다.
                    self.reviews.remove(at: indexPath.row)
                    // 테이블 뷰에서 해당 행을 삭제합니다.
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
}
