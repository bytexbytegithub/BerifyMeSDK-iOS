import UIKit

/// Error view
class ErrorView: UIView {
    private let backButton: UIButton
    private let backImageView: UIImageView
    private let logoImageView: UIImageView
    private let emojiLabel: UILabel
    private let titleLabel: UILabel
    private let messageLabel: UILabel
    private let retryButton: UIButton
    private let footerView: FooterView
    
    private let onRetry: () -> Void
    
    init(message: String, onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
        backButton = UIButton(type: .system)
        backImageView = UIImageView()
        logoImageView = UIImageView()
        emojiLabel = UILabel()
        titleLabel = UILabel()
        messageLabel = UILabel()
        retryButton = UIButton(type: .system)
        footerView = FooterView()
        
        super.init(frame: .zero)
        setupUI(message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(message: String) {
        backgroundColor = .white

        if let url = URL(string: "https://idv.berify.me/arrowLeft.png") {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.backImageView.image = image
                }
            }.resume()
        }
        backImageView.contentMode = .scaleAspectFit
        backImageView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        addSubview(backButton)
        backButton.addSubview(backImageView)

        if let url = URL(string: "https://idv.berify.me/little-berify.png") {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.logoImageView.image = image
                }
            }.resume()
        }
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoImageView)

        emojiLabel.text = ":-("
        emojiLabel.font = .systemFont(ofSize: 60, weight: .bold)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiLabel)
        
        titleLabel.text = "Oops!"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = UIColor(white: 0.41, alpha: 1.0)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        retryButton.setTitle("Try again", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        retryButton.backgroundColor = .black
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 25
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(retryButton)

        footerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerView)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            backImageView.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            backImageView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            backImageView.widthAnchor.constraint(equalToConstant: 32),
            backImageView.heightAnchor.constraint(equalToConstant: 32),
            
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 44),
            logoImageView.heightAnchor.constraint(equalToConstant: 44),
            
            emojiLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            emojiLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 200),
            retryButton.heightAnchor.constraint(equalToConstant: 52),
            
            footerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            footerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    @objc private func retryTapped() {
        onRetry()
    }
}
