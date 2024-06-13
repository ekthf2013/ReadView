import UIKit
import Firebase
import FirebaseFirestore

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []            // 모든 게시글 데이터를 저장하는 배열
    var filteredPosts: [Post] = []    // 검색 결과를 저장하는 배열
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 검색바와 테이블뷰의 델리게이트 설정
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // PostTableViewCell 등록
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "PostSearchCell")
        
        // 초기 데이터 로드
        listenForPosts()
        
        // 키보드 해제를 위한 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // 테이블 뷰 셀 클릭 인식
        tapGesture.delegate = self // 제스처 델리게이트 설정
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Firebase Firestore에서 게시글 데이터를 실시간으로 로드
    func listenForPosts() {
        let db = Firestore.firestore()
        db.collection("reviews").addSnapshotListener { (snapshot, error) in
            // 게시글 데이터를 Post 객체 배열로 변환
            self.posts = snapshot?.documents.compactMap { document -> Post? in
                return try? document.data(as: Post.self)
            } ?? []
            
            // 필터링된 게시글 배열을 초기화
            self.filteredPosts = self.posts
            self.tableView.reloadData()
        }
    }
    
    // 검색바의 텍스트가 변경될 때 호출
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredPosts = posts // 검색어가 없으면 전체 게시글을 표시
        } else {
            // 검색어가 포함된 게시글 필터링
            filteredPosts = posts.filter { post in
                return post.title.lowercased().contains(searchText.lowercased()) || post.genre.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPosts.count // 필터링된 게시글의 수를 반환
    }
    
    // 각 셀에 데이터를 설정
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostSearchCell", for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        let post = filteredPosts[indexPath.row]
        cell.titleLabel.text = post.title
        cell.genreLabel.text = post.genre
        return cell
    }
    
    // 셀이 선택되었을 때 호출
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = filteredPosts[indexPath.row]
        showDetailViewController(post: selectedPost)
    }

    // 상세 화면으로 이동
    func showDetailViewController(post: Post) {
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return
        }
        detailViewController.post = post
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
