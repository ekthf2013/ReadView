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
    }
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let title = titleTextField.text, !title.isEmpty,
              let review = reviewTextView.text, !review.isEmpty,
              let image = imageView.image,
              let userEmail = Auth.auth().currentUser?.email else {
            showAlert(message: "모든 필드를 입력하세요.")
            return
        }
        
        if let genre = genres[safe: genrePickerView.selectedRow(inComponent: 0)] {
            // Firebase Firestore에 데이터 저장
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
                    //고유 문서 ID 얻기 위한 변수
                    let docRef = db.collection("reviews").document()

                    docRef.setData([
                        "id": docRef.documentID,
                        "title": title,
                        "review": review,
                        "genre": genre,
                        "imageURL": url.absoluteString,
                        "createdAt": Timestamp(date: Date()),
                        "email": userEmail // 작성자 이메일 추가
                    ]) { error in
                        if let error = error {
                            self.showAlert(message: "리뷰 저장 실패: \(error.localizedDescription)")
                        } else {
                            self.showAlert(message: "리뷰가 저장되었습니다.")
                            self.clearFields()
                        }
                    }
                }
            }
        } else {
            showAlert(message: "장르를 선택하세요.")
        }
    }

    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
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
