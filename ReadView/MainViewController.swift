import UIKit
import FirebaseFirestore
import SDWebImage

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        fetchPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 데이터를 새로 로드합니다.
        fetchPosts()
    }
    
    func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("reviews").order(by: "createdAt", descending: true).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            self.posts = documents.compactMap { (document) -> Post? in
                return try? document.data(as: Post.self)
            }
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCollectionViewCell
        let post = posts[indexPath.item]
        
        cell.titleLabel.text = post.title
        cell.genreLabel.text = post.genre
        cell.imageView.sd_setImage(with: URL(string: post.imageURL), placeholderImage: UIImage(named: "placeholder"))
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.frame.width
        let cellWidth = (collectionViewWidth - 10) / 2 // 한 행에 두 개의 셀을 배치하기 위해 셀 너비를 조정합니다. 여기서 10은 두 셀 사이의 간격입니다.
        let cellHeight: CGFloat = 200 // 셀의 높이를 설정합니다.
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 셀 사이의 세로 간격을 설정합니다.
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 셀 사이의 가로 간격을 설정합니다.
    }
    
    // MARK: - Navigation
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = posts[indexPath.item]
        showDetailViewController(post: post)
    }

    func showDetailViewController(post: Post) {
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return
        }
        detailViewController.post = post
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
