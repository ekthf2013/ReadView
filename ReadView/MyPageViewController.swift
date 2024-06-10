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
            .getDocuments { (querySnapshot, error) in
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
    
    // UITableViewDelegate 메소드 (선택 사항)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

}
