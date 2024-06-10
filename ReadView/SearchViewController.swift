import UIKit
import Firebase
import FirebaseFirestore

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []
    var filteredPosts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // PostTableViewCell 등록
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "PostSearchCell")
        
        // 초기 데이터 로드
        listenForPosts()
    }
    
    func listenForPosts() {
        // Firebase에서 게시글 데이터를 실시간으로 로드합니다.
        let db = Firestore.firestore()
        db.collection("reviews").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
            } else {
                self.posts = snapshot?.documents.compactMap { document -> Post? in
                    return try? document.data(as: Post.self)
                } ?? []
                self.filteredPosts = self.posts
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredPosts = posts
        } else {
            filteredPosts = posts.filter { post in
                return post.title.lowercased().contains(searchText.lowercased()) || post.genre.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    // UITableViewDataSource 메서드
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostSearchCell", for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        let post = filteredPosts[indexPath.row]
        cell.titleLabel.text = post.title
        cell.genreLabel.text = post.genre
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = filteredPosts[indexPath.row]
        showDetailViewController(post: selectedPost)
    }

    func showDetailViewController(post: Post) {
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return
        }
        detailViewController.post = post
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
