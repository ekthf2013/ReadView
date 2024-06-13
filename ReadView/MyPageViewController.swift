import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 데이터를 새로 고침
        fetchUserReviews()
    }
    // 로그아웃 버튼 클릭 시 호출되는 메소드
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            tabBarController?.tabBar.isHidden = true
            
            // 로그아웃 성공 시 로그인 화면으로 이동
            if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                navigationController?.setViewControllers([loginVC], animated: true)
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func likedPostsButtonTapped(_ sender: UIButton) {
        if let likedPostsVC = storyboard?.instantiateViewController(withIdentifier: "LikedPostsViewController") as? LikedPostsViewController {
            navigationController?.pushViewController(likedPostsVC, animated: true)
        }
    }
    // 사용자가 작성한 리뷰를 Firestore에서 가져오는 메소드
    func fetchUserReviews() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                // Firestore에서 가져온 데이터를 Post 객체로 변환하여 배열에 저장
                self.reviews = querySnapshot?.documents.compactMap { document -> Post? in
                    try? document.data(as: Post.self)
                } ?? []
                self.tableView.reloadData() // 테이블 뷰 리로드
            }
    }
    
    // UITableViewDataSource 메소드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count // 리뷰 배열의 개수만큼 셀 행 수 반환
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as? MyPageTableViewCell else {
            return UITableViewCell()
        }
        let review = reviews[indexPath.row]
        cell.configure(with: review) // 셀에 리뷰 데이터 설정
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 셀의 높이 반환 (원하는 높이로 설정)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "내가 작성한 리뷰" // 섹션 헤더 제목 설정
    }
    
    // UITableViewDelegate 메소드
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedReview = reviews[indexPath.row]
        navigateToReviewViewController(with: selectedReview) // 리뷰 상세 화면으로 이동
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteReview(at: indexPath) // 리뷰 삭제
        }
    }
    
    // 리뷰 삭제 메소드
    private func deleteReview(at indexPath: IndexPath) {
        let review = reviews[indexPath.row]
        Firestore.firestore().collection("reviews").document(review.id).delete { [weak self] error in
            guard let self = self else { return }
            print("Document successfully deleted!")
            self.reviews.remove(at: indexPath.row) // 배열에서 삭제
            self.tableView.deleteRows(at: [indexPath], with: .fade) // 테이블 뷰에서 삭제
        }
    }
    
    // ReviewViewController로 이동하는 메소드
    private func navigateToReviewViewController(with review: Post) {
        guard let reviewVC = storyboard?.instantiateViewController(withIdentifier: "ReviewViewController") as? ReviewViewController else { return }
        
        reviewVC.selectedReview = review // 선택된 리뷰 전달
        
        if let imageURL = URL(string: review.imageURL) {
            reviewVC.downloadImageAndNavigate(imageURL: imageURL) // 리뷰 이미지 다운로드 후 이동
        } else {
            navigationController?.pushViewController(reviewVC, animated: true) // 이미지 없으면 바로 이동
        }
    }
}

//// ReviewViewController 확장
extension ReviewViewController {
    
    // 이미지 다운로드 후 화면 이동 메소드
    func downloadImageAndNavigate(imageURL: URL) {
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self.reviewImage = image // 리뷰 이미지 설정
                self.navigationController?.pushViewController(self, animated: true) // 화면 이동
            }
        }.resume()
    }
}
