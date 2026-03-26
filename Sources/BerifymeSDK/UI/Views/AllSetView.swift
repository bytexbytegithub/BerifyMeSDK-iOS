import UIKit

/// Completion view (aligned with React Native SDK UI)
class AllSetView: UIView {
    private let logoImageView: UIImageView
    private let titleLabel: UILabel
    private let nameLabel: UILabel
    private let descriptionLabel: UILabel
    private let continueButton: UIButton
    private let loadingIndicator: UIActivityIndicatorView
    private let footerView: FooterView
    
    private let user: User?
    private let token: String?
    private let onComplete: (String?) -> Void
    
    private var isLoading: Bool = false {
        didSet { updateLoadingUI() }
    }
    
    init(
        user: User?,
        token: String?,
        onComplete: @escaping (String?) -> Void
    ) {
        self.user = user
        self.token = token
        self.onComplete = onComplete
        
        logoImageView = UIImageView()
        titleLabel = UILabel()
        nameLabel = UILabel()
        descriptionLabel = UILabel()
        continueButton = UIButton(type: .system)
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        footerView = FooterView()
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // Logo
        if let imageURL = URL(string: "https://idv.berify.me/little-berify.png") {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.logoImageView.image = image
                }
            }.resume()
        }
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoImageView)
        
        // Title
        titleLabel.text = "You're Berified,"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Name
        nameLabel.text = user?.fullName ?? ""
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Description
        descriptionLabel.text = "Thank you for securely verifying your identity through Berify.me 🎉"
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = UIColor(white: 0.41, alpha: 1.0) // #696969
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)
        
        // Continue button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        continueButton.backgroundColor = .black
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 20
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(continueButton)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        // Footer
        footerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerView)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 44),
            logoImageView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            continueButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 52),

            loadingIndicator.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -20),
            
            footerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    @objc private func continueTapped() {
        guard !isLoading else { return }
        guard let user = user else { return }
        guard let token = token else { return }
        
        isLoading = true
        
        Task {
            do {
                guard let tools = BerifymeSDK.shared.tools else {
                    await MainActor.run {
                        self.isLoading = false
                        self.onComplete(nil)
                    }
                    return
                }
                
                let res = try await tools.getGeneralVerificationToken(userId: user.id, token: token)
                await MainActor.run {
                    self.isLoading = false
                    self.onComplete(res.generalVerificationToken)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.onComplete(nil)
                }
            }
        }
    }
    
    private func updateLoadingUI() {
        continueButton.isEnabled = !isLoading
        continueButton.alpha = isLoading ? 0.6 : 1.0
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}
