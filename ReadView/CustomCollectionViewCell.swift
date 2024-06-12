import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        self.layer.borderColor = UIColor.black.cgColor // 테두리 색상
        self.layer.borderWidth = 1.0 // 테두리 두께
        self.layer.cornerRadius = 8.0 // 모서리 둥글게
    }
}
