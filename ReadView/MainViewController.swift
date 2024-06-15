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
        // 화면이 나타날 때마다 데이터를 새로 고침
        fetchPosts()
    }
    
    func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("reviews").order(by: "createdAt", descending: true).getDocuments { (snapshot, error) in
            if error != nil {
                self.showAlert(message: "데이터를 불러오는 중 오류가 발생했습니다")
                return
            }
            guard let documents = snapshot?.documents else {
                self.showAlert(message: "데이터가 없습니다.")
                return
            }
            self.posts = documents.compactMap { (document) -> Post? in
                return try? document.data(as: Post.self)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
        
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
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.frame.width
        let cellWidth = (collectionViewWidth - 30) / 2 // 두 셀 사이의 간격을 포함하여 계산
        let cellHeight: CGFloat = 200 // 셀의 높이 설정
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 셀 사이의 세로 간격 설정
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 셀 사이의 가로 간격 설정
    }
        
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

    // 메시지 표시
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
