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
        
        // 선택된 리뷰가 있는지 확인하고, 있으면 UI를 설정합니다.
        if let review = selectedReview {
            titleTextField.text = review.title
            reviewTextView.text = review.review
            imageView.image = reviewImage
        }
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
        
        if let genre = genres[safe: genrePickerView.selectedRow(inComponent: 0)] {
            if let selectedReview = selectedReview {
                // 선택된 리뷰가 있는 경우에는 수정을 수행합니다.
                updateReview(selectedReview, with: title, reviewText, genre, image)
            } else {
                // 선택된 리뷰가 없는 경우에는 새로운 리뷰를 추가합니다.
                addNewReview(with: title, reviewText, genre, image, userEmail)
            }
        } else {
            showAlert(message: "장르를 선택하세요.")
        }
    }

    private func updateReview(_ review: Post, with title: String, _ reviewText: String, _ genre: String, _ image: UIImage) {
        // 선택된 리뷰의 필드를 업데이트합니다.
        var updatedReview = review // 새로운 변수에 선택된 리뷰를 복사합니다.
        updatedReview.title = title // title 속성을 수정합니다.
        updatedReview.review = reviewText // review 속성을 수정합니다.

        // Firestore에서 선택된 리뷰 업데이트
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let imageData = image.jpegData(compressionQuality: 0.8)!
        let imageRef = storage.reference().child("images/\(review.id).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                self.showAlert(message: "이미지 업로드 실패: \(error!.localizedDescription)")
                return
            }
            imageRef.downloadURL { url, error in
                guard url != nil else {
                    self.showAlert(message: "이미지 URL 가져오기 실패: \(error!.localizedDescription)")
                    return
                }
                
                // Firestore에서 선택된 리뷰 업데이트
                let reviewRef = db.collection("reviews").document(review.id)
                reviewRef.updateData([
                    "title": title,
                    "review": reviewText,
                    "genre": genre,
                    "createdAt": FieldValue.serverTimestamp() // 현재 시간으로 업데이트
                ]) { error in
                    if let error = error {
                        self.showAlert(message: "리뷰 수정 실패: \(error.localizedDescription)")
                    } else {
                        // 리뷰가 업데이트되었음을 알립니다.
                        self.showAlert1(message: "리뷰가 수정되었습니다.")
                    }
                }
            }
        }
    }


    private func addNewReview(with title: String, _ reviewText: String, _ genre: String, _ image: UIImage, _ userEmail: String) {
        // Firestore에 새 리뷰 추가
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let imageData = image.jpegData(compressionQuality: 0.8)!
        let imageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                self.showAlert(message: "이미지 업로드 실패: \(error!.localizedDescription)")
                return
            }
            imageRef.downloadURL { url, error in
                guard let url = url else {
                    self.showAlert(message: "이미지 URL 가져오기 실패: \(error!.localizedDescription)")
                    return
                }
                
                // Firestore에 새 리뷰 추가
                let docRef = db.collection("reviews").document()
                docRef.setData([
                    "id": docRef.documentID,
                    "title": title,
                    "review": reviewText,
                    "genre": genre,
                    "imageURL": url.absoluteString,
                    "createdAt": Timestamp(date: Date()),
                    "email": userEmail // 작성자 이메일 추가
                ]) { error in
                    if let error = error {
                        self.showAlert(message: "리뷰 저장 실패: \(error.localizedDescription)")
                    } else {
                        self.clearFields()
                        self.showAlert1(message: "리뷰가 저장되었습니다.")
                    }
                }
            }
        }
    }


    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert1(message: String) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            // 확인 버튼을 누를 때 홈 화면으로 이동
            self.tabBarController?.selectedIndex = 0 // 홈 탭의 인덱스에 해당하는 값을 지정
        })
        present(alertController, animated: true, completion: nil)
    }
    
    private func clearFields() {
        titleTextField.text = ""
        imageView.image = nil
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
    
    // UIImagePickerController Delegate methods
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
