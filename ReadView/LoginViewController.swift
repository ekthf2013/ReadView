import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 탭 제스처를 추가하여 키보드를 해제할 수 있게 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // 입력 필드가 비어 있는 경우 처리
            showAlert(message: "이메일과 비밀번호를 입력하세요.")
            return
        }

        // 로딩 인디케이터 시작
        let loadingAlert = UIAlertController(title: nil, message: "로그인 중...", preferredStyle: .alert)
        present(loadingAlert, animated: true, completion: nil)

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            // 로딩 인디케이터 종료
            loadingAlert.dismiss(animated: true, completion: nil)

            guard let self = self else { return }
            if error != nil {
                // 로그인 실패 처리
                self.showAlert(message: "로그인 실패")
            } else {
                // 로그인 성공 시 탭 바 컨트롤러로 이동
                if let mainTabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                    mainTabBarController.modalPresentationStyle = .fullScreen
                    self.present(mainTabBarController, animated: true, completion: nil)
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
