import UIKit

class FooterView: UIView {
    private let iconImageView: UIImageView
    private let textLabel: UILabel
    private let stackView: UIStackView
    
    override init(frame: CGRect) {
        iconImageView = UIImageView()
        textLabel = UILabel()
        stackView = UIStackView()
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        if let imageURL = URL(string: "https://idv.berify.me/security.png") {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.iconImageView.image = image
                }
            }.resume()
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        textLabel.text = "Securely powered by Berify.me"
        textLabel.font = .systemFont(ofSize: 12, weight: .medium)
        textLabel.textColor = UIColor(white: 0.41, alpha: 1.0) // #696969
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
