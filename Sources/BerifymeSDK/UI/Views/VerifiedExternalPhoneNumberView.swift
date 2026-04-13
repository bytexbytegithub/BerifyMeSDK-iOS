import UIKit

/// Verified external phone number view (aligned with RN SDK logic)
class VerifiedExternalPhoneNumberView: UIView {
    private enum Mode {
        case loading
        case welcomeBack(loginStatus: PageStatus, fullName: String?)
    }
    
    private let loadingIndicator: UIActivityIndicatorView
    private let welcomeContainerView: UIView
    private let welcomeEmojiLabel: UILabel
    private let welcomeTitleLabel: UILabel
    private let welcomeNameLabel: UILabel
    private let welcomeDescriptionLabel: UILabel
    private let takeSelfieButton: UIButton
    
    private let token: String?
    private let phoneNumber: String
    
    /// When checkDeviceId matches (passkey only) complete directly → AllSet
    private let onComplete: (User) -> Void
    
    /// When KYC selfie needed, external switches to corresponding login page
    private let onSelectLogin: (PageStatus) -> Void
    /// When welcome back is shown, notify modal to set currentUser for Incode/Clear flow (align VerifyUserView)
    private let onUserVerified: (User) -> Void
    private let onError: (String) -> Void
    
    private var mode: Mode = .loading
    
    init(
        token: String?,
        phoneNumber: String,
        onComplete: @escaping (User) -> Void,
        onSelectLogin: @escaping (PageStatus) -> Void,
        onUserVerified: @escaping (User) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.token = token
        self.phoneNumber = phoneNumber
        self.onComplete = onComplete
        self.onSelectLogin = onSelectLogin
        self.onUserVerified = onUserVerified
        self.onError = onError
        
        loadingIndicator = UIActivityIndicatorView(style: .large)
        welcomeContainerView = UIView()
        welcomeEmojiLabel = UILabel()
        welcomeTitleLabel = UILabel()
        welcomeNameLabel = UILabel()
        welcomeDescriptionLabel = UILabel()
        takeSelfieButton = UIButton(type: .system)
        
        super.init(frame: .zero)
        setupUI()
        handleVerifiedExternalPhoneNumber()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        // Welcome back UI
        welcomeContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(welcomeContainerView)

        // 👋 (align RN welcome back icon)
        welcomeEmojiLabel.text = "👋"
        welcomeEmojiLabel.font = .systemFont(ofSize: 48, weight: .bold)
        welcomeEmojiLabel.textAlignment = .center
        welcomeEmojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        welcomeTitleLabel.text = "Welcome back,"
        welcomeTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        welcomeTitleLabel.textAlignment = .center
        welcomeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        welcomeNameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        welcomeNameLabel.textAlignment = .center
        welcomeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        welcomeDescriptionLabel.text = "Take a selfie to verify your identity."
        welcomeDescriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        welcomeDescriptionLabel.textColor = UIColor(white: 0.41, alpha: 1.0)
        welcomeDescriptionLabel.textAlignment = .center
        welcomeDescriptionLabel.numberOfLines = 0
        welcomeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        takeSelfieButton.setTitle("Take my selfie", for: .normal)
        takeSelfieButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        takeSelfieButton.backgroundColor = .black
        takeSelfieButton.setTitleColor(.white, for: .normal)
        takeSelfieButton.layer.cornerRadius = 20
        takeSelfieButton.addTarget(self, action: #selector(takeSelfieTapped), for: .touchUpInside)
        takeSelfieButton.translatesAutoresizingMaskIntoConstraints = false
        
        welcomeContainerView.addSubview(welcomeEmojiLabel)
        welcomeContainerView.addSubview(welcomeTitleLabel)
        welcomeContainerView.addSubview(welcomeNameLabel)
        welcomeContainerView.addSubview(welcomeDescriptionLabel)
        welcomeContainerView.addSubview(takeSelfieButton)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            welcomeContainerView.topAnchor.constraint(equalTo: topAnchor),
            welcomeContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            welcomeContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            welcomeContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            welcomeEmojiLabel.topAnchor.constraint(equalTo: welcomeContainerView.topAnchor, constant: 96),
            welcomeEmojiLabel.leadingAnchor.constraint(equalTo: welcomeContainerView.leadingAnchor, constant: 20),
            welcomeEmojiLabel.trailingAnchor.constraint(equalTo: welcomeContainerView.trailingAnchor, constant: -20),
            
            welcomeTitleLabel.topAnchor.constraint(equalTo: welcomeEmojiLabel.bottomAnchor, constant: 16),
            welcomeTitleLabel.leadingAnchor.constraint(equalTo: welcomeContainerView.leadingAnchor, constant: 20),
            welcomeTitleLabel.trailingAnchor.constraint(equalTo: welcomeContainerView.trailingAnchor, constant: -20),
            
            welcomeNameLabel.topAnchor.constraint(equalTo: welcomeTitleLabel.bottomAnchor, constant: 4),
            welcomeNameLabel.leadingAnchor.constraint(equalTo: welcomeContainerView.leadingAnchor, constant: 20),
            welcomeNameLabel.trailingAnchor.constraint(equalTo: welcomeContainerView.trailingAnchor, constant: -20),
            
            welcomeDescriptionLabel.topAnchor.constraint(equalTo: welcomeNameLabel.bottomAnchor, constant: 12),
            welcomeDescriptionLabel.leadingAnchor.constraint(equalTo: welcomeContainerView.leadingAnchor, constant: 20),
            welcomeDescriptionLabel.trailingAnchor.constraint(equalTo: welcomeContainerView.trailingAnchor, constant: -20),
            
            takeSelfieButton.topAnchor.constraint(equalTo: welcomeDescriptionLabel.bottomAnchor, constant: 32),
            takeSelfieButton.centerXAnchor.constraint(equalTo: welcomeContainerView.centerXAnchor),
            takeSelfieButton.widthAnchor.constraint(equalToConstant: 200),
            takeSelfieButton.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        updateModeUI()
    }
    
    private func handleVerifiedExternalPhoneNumber() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                guard let userAPI = BerifymeSDK.shared.user else {
                    await MainActor.run {
                        loadingIndicator.stopAnimating()
                        onError("API not initialized")
                    }
                    return
                }
                
                // 1. Create user (if not exists)
                let createRes = try await userAPI.createUserByVerifiedExternalPhoneNumber(
                    phoneNumber: phoneNumber,
                    token: token
                )
                
                guard let user = createRes.user else {
                    await MainActor.run {
                        loadingIndicator.stopAnimating()
                        onError(createRes.error ?? "Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                // 2. Check deviceId (if match, AllSet) — align RN: use persisted deviceId
                if let sessionToken = token {
                    let deviceId = DeviceIdStore.getOrCreate()
                    let deviceRes = try? await userAPI.checkDeviceId(
                        phoneNumber: phoneNumber,
                        deviceId: deviceId,
                        token: sessionToken
                    )
                    if let deviceUser = deviceRes?.user {
                        await MainActor.run {
                            loadingIndicator.stopAnimating()
                            onComplete(deviceUser)
                        }
                        return
                    }
                }
                
                // 3. Get vender (if present show Welcome back; else Vender selection)
                let venderRes = try await userAPI.getUserVenderByPhone(phoneNumber: phoneNumber, token: token)
                if venderRes.error != nil {
                    await MainActor.run {
                        loadingIndicator.stopAnimating()
                        onError("Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                let loginStatus = PageStatus.loginStatus(forVendor: venderRes.vender ?? "")
                
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    
                    if let loginStatus = loginStatus {
                        onUserVerified(user)  // 設定 modal currentUser，按下 Take my selfie 時 Clear/Incode 才可取得 user
                        mode = .welcomeBack(loginStatus: loginStatus, fullName: venderRes.fullName)
                        updateModeUI()
                    } else {
                        // No vender; modal onComplete will route to onboarding (e.g. incodeOnBoarding)
                        onComplete(user)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    onError("Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                }
            }
        }
    }
    
    private func updateModeUI() {
        switch mode {
        case .loading:
            loadingIndicator.isHidden = false
            welcomeContainerView.isHidden = true
        case .welcomeBack(_, let fullName):
            loadingIndicator.isHidden = true
            welcomeContainerView.isHidden = false
            welcomeNameLabel.text = fullName ?? ""
        }
    }
    
    @objc private func takeSelfieTapped() {
        if case .welcomeBack(let loginStatus, _) = mode {
            onSelectLogin(loginStatus)
        }
    }
}
