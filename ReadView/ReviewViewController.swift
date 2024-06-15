import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// Array extension to handle safe indexing
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class ReviewViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var genrePickerView: UIPickerView!
    @IBOutlet weak var reviewTextView: UITextView!
    
    var selectedReview: Post? // 리뷰 데이터를 저장할 프로퍼티
    var reviewImage: UIImage? // 리뷰 이미지를 저장할 프로퍼티
    
    var currentUserEmail: String? // 현재 사용자의 이메일을 저장하기 위한 변수
    var genres = ["문학 소설", "추리 소설", "스릴러 소설", "로맨스 소설", "에세이", "시", "동화책", "기타"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 사용자 정보 가져오기
        if let user = Auth.auth().currentUser {
            currentUserEmail = user.email
        }
        
        genrePickerView.delegate = self
        genrePickerView.dataSource = self
        
        // 선택된 리뷰가 있는지 확인하고, 있으면 UI를 설정
        if let review = selectedReview {
            titleTextField.text = review.title
            reviewTextView.text = review.review
            imageView.image = reviewImage
        } else {
            // 선택된 리뷰가 없으면 기본 이미지를 설정
            imageView.image = UIImage(named: "Picture")
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        clearFields()
    }
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty,
              let reviewText = reviewTextView.text, !reviewText.isEmpty,
              let image = imageView.image,
              let userEmail = currentUserEmail else {
            showAlert(message: "모든 필드를 입력하세요.")
            return
        }
        
        guard let genre = genres[safe: genrePickerView.selectedRow(inComponent: 0)] else {
            showAlert(message: "장르를 선택하세요.")
            return
        }
        
        uploadImageAndGetURL(image) { [weak self] result in
            switch result {
            case .success(let url):
                if let selectedReview = self?.selectedReview {
                    // 선택된 리뷰가 있는 경우에 수정
                    self?.updateReview(selectedReview, with: title, reviewText, genre, url)
                } else {
                    // 선택된 리뷰가 없는 경우에는 새로운 리뷰 추가
                    self?.addNewReview(with: title, reviewText, genre, url, userEmail)
                }
            case .failure(let error):
                self?.showAlert(message: "이미지 업로드 실패")
            }
        }
    }
    
    private func uploadImageAndGetURL(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        let storage = Storage.storage()
        let imageData = image.jpegData(compressionQuality: 0.8)!
        let imageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                completion(.failure(error!))
                return
            }
            imageRef.downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(error!))
                    return
                }
                completion(.success(url))
            }
        }
    }

    private func updateReview(_ review: Post, with title: String, _ reviewText: String, _ genre: String, _ imageURL: URL) {
        // Firestore에서 선택된 리뷰 업데이트
        let db = Firestore.firestore()
        let reviewRef = db.collection("reviews").document(review.id)
        
        reviewRef.updateData([
            "title": title,
            "review": reviewText,
            "genre": genre,
            "imageURL": imageURL.absoluteString,
            "createdAt": FieldValue.serverTimestamp() // 현재 시간으로 업데이트
        ]) { error in
            if let error = error {
                self.showAlert(message: "리뷰 수정 실패: \(error.localizedDescription)")
            } else {
                self.showAlert(message: "리뷰가 수정되었습니다.", action: {
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }

    private func addNewReview(with title: String, _ reviewText: String, _ genre: String, _ imageURL: URL, _ userEmail: String) {
        // Firestore에 새 리뷰 추가
        let db = Firestore.firestore()
        let docRef = db.collection("reviews").document()
        
        docRef.setData([
            "id": docRef.documentID,
            "title": title,
            "review": reviewText,
            "genre": genre,
            "imageURL": imageURL.absoluteString,
            "createdAt": Timestamp(date: Date()),
            "email": userEmail // 작성자 이메일 추가
        ]) { error in
            if let error = error {
                self.showAlert(message: "리뷰 저장 실패: \(error.localizedDescription)")
            } else {
                self.clearFields()
                self.showAlert(message: "리뷰가 저장되었습니다.", action: {
                    self.tabBarController?.selectedIndex = 0 // 홈 탭의 인덱스에 해당하는 값을 지정
                })
            }
        }
    }
    
    private func showAlert(message: String, action: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "확인", style: .default) { _ in
            action?()
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //삭제버튼 눌렀을 때 내용 초기화
    private func clearFields() {
        titleTextField.text = ""
        imageView.image = UIImage(named: "Picture")
        genrePickerView.selectRow(0, inComponent: 0, animated: false)
        reviewTextView.text = ""
    }
    
    // UIPickerView DataSource and Delegate methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genres.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genres[row]
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
