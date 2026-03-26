import UIKit

/// Verify user view (existing user)
class VerifyUserView: UIView {
    private enum Mode {
        case codeEntry
        case welcomeBack(loginStatus: PageStatus, fullName: String?)
    }
    
    private let codeTextField: UITextField
    private let resendButton: UIButton
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel
    private let errorLabel: UILabel
    private let loadingIndicator: UIActivityIndicatorView
    private let backButton: UIButton
    
    private let welcomeContainerView: UIView
    private let welcomeEmojiLabel: UILabel
    private let welcomeTitleLabel: UILabel
    private let welcomeNameLabel: UILabel
    private let welcomeDescriptionLabel: UILabel
    private let takeSelfieButton: UIButton
    private let footerView: FooterView
    
    private let token: String?
    private let phoneNumber: String
    private let defaultCountryIso2: String
    
    /// When checkDeviceId matches (passkey only) complete directly → AllSet
    private let onComplete: (User) -> Void
    
    /// When KYC selfie needed, external switches to corresponding login page
    private let onSelectLogin: (PageStatus) -> Void
    /// When verification succeeds and welcomeBack (Take my selfie), notify modal to set currentUser for Incode/Clear flow
    private let onUserVerified: (User) -> Void
    private let onError: (String) -> Void
    private let onBack: (() -> Void)?
    
    private var countdown: Int = 60
    private var countdownTimer: Timer?
    private var isLoading: Bool = false
    private var mode: Mode = .codeEntry
    
    init(
        token: String?,
        phoneNumber: String,
        defaultCountryIso2: String = "US",
        onComplete: @escaping (User) -> Void,
        onSelectLogin: @escaping (PageStatus) -> Void,
        onUserVerified: @escaping (User) -> Void,
        onError: @escaping (String) -> Void,
        onBack: (() -> Void)? = nil
    ) {
        self.token = token
        self.phoneNumber = phoneNumber
        self.defaultCountryIso2 = defaultCountryIso2.uppercased()
        self.onComplete = onComplete
        self.onSelectLogin = onSelectLogin
        self.onUserVerified = onUserVerified
        self.onError = onError
        self.onBack = onBack
        
        codeTextField = UITextField()
        resendButton = UIButton(type: .system)
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        errorLabel = UILabel()
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        backButton = UIButton(type: .system)
        
        welcomeContainerView = UIView()
        welcomeEmojiLabel = UILabel()
        welcomeTitleLabel = UILabel()
        welcomeNameLabel = UILabel()
        welcomeDescriptionLabel = UILabel()
        takeSelfieButton = UIButton(type: .system)
        footerView = FooterView()
        
        super.init(frame: .zero)
        setupUI()
        startCountdown()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // Back button (align RN SDK: use arrowLeft.png)
        if let _ = onBack {
            let backImageView = UIImageView()
            if let imageURL = URL(string: "https://idv.berify.me/arrowLeft.png") {
                URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                    guard let data = data, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        backImageView.image = image
                    }
                }.resume()
            }
            backImageView.contentMode = .scaleAspectFit
            backImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                backImageView.widthAnchor.constraint(equalToConstant: 24),
                backImageView.heightAnchor.constraint(equalToConstant: 24)
            ])
            backButton.addSubview(backImageView)
            NSLayoutConstraint.activate([
                backImageView.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
                backImageView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
            ])
            backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
            backButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(backButton)
        }
        
        titleLabel.text = "Verify your identity"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        let gray = UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1) // #696969, align RN
        let attributedText = NSMutableAttributedString(
            string: "Enter the 6-digit code sent to ",
            attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: gray]
        )
        attributedText.append(NSAttributedString(
            string: phoneNumber,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.label]
        ))
        descriptionLabel.attributedText = attributedText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)
        
        codeTextField.placeholder = "Enter code"
        codeTextField.keyboardType = .numberPad
        codeTextField.textAlignment = .left
        codeTextField.font = .systemFont(ofSize: 16, weight: .medium)
        codeTextField.textColor = .black // Align RN SDK: color: 'black'
        codeTextField.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) // #f2f2f2, align RN
        codeTextField.layer.cornerRadius = 12
        codeTextField.layer.borderWidth = 2
        codeTextField.layer.borderColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0).cgColor
        codeTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        codeTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        codeTextField.leftViewMode = .always
        codeTextField.rightViewMode = .always
        codeTextField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(codeTextField)
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1) // #696969, align RN
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        resendButton.setTitle("Resend code", for: .normal)
        resendButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        resendButton.setTitleColor(UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1.0), for: .normal)
        resendButton.setTitleColor(.gray, for: .disabled)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        resendButton.isEnabled = false
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resendButton)
        
        errorLabel.font = .systemFont(ofSize: 12, weight: .medium)
        errorLabel.textColor = UIColor(red: 1, green: 84/255, blue: 84/255, alpha: 1) // #FF5454, align RN
        errorLabel.textAlignment = .right
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorLabel)
        
        setupWelcomeBackUI()
        
        footerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerView)
        
        var constraints: [NSLayoutConstraint] = []
        
        // Align RN: ph={8}, reduce spacing between back button and title
        if let _ = onBack {
            constraints.append(contentsOf: [
                backButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44),
            ])
        }
        
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: (onBack != nil ? backButton.bottomAnchor : topAnchor), constant: (onBack != nil ? 12 : 16)),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            codeTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            codeTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            codeTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            codeTextField.heightAnchor.constraint(equalToConstant: 48),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: codeTextField.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: codeTextField.trailingAnchor, constant: -20),
            
            resendButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 8),
            resendButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            resendButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -8),
            
            errorLabel.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: resendButton.trailingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            errorLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            welcomeContainerView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            welcomeContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            welcomeContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            welcomeContainerView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            
            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            footerView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        NSLayoutConstraint.activate(constraints)
        updateModeUI()
    }
    
    @objc private func codeChanged() {
        guard let code = codeTextField.text else { return }
        
        let filteredCode = String(code.prefix(6).filter { $0.isNumber })
        if filteredCode != code {
            codeTextField.text = filteredCode
        }
        
        if errorLabel.isHidden == false && !filteredCode.isEmpty {
            errorLabel.isHidden = true
        }
        
        if filteredCode.count == 6 && !isLoading {
            verifyCode(filteredCode)
        }
    }
    
    private func setupWelcomeBackUI() {
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
    }
    
    private func startCountdown() {
        countdown = 60
        updateResendButton()
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown <= 0 {
                self.countdownTimer?.invalidate()
                self.countdown = 0
            }
            self.updateResendButton()
        }
    }
    
    private func updateResendButton() {
        if countdown > 0 {
            // Align RN: 60s countdown display "00:XX"
            resendButton.setTitle(
                String(format: "Resend available in 00:%02d", countdown),
                for: .disabled
            )
            resendButton.isEnabled = false
        } else {
            resendButton.setTitle("Resend code", for: .normal)
            resendButton.isEnabled = true
        }
    }
    
    @objc private func backTapped() {
        onBack?()
    }
    
    @objc private func resendTapped() {
        guard !isLoading, countdown == 0 else { return }
        
        isLoading = true
        loadingIndicator.startAnimating()
        resendButton.isEnabled = false
        
        Task {
            do {
                guard let authAPI = BerifymeSDK.shared.auth else {
                    await MainActor.run {
                        isLoading = false
                        loadingIndicator.stopAnimating()
                        onError("Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                let processedPhone = PhoneNumberProcessor.process(phoneNumber, countryIso2: defaultCountryIso2.lowercased())
                let response = try await authAPI.sendPhoneNumberCode(
                    phoneNumber: processedPhone,
                    token: token
                )
                
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    
                    if response.success == true {
                        startCountdown()
                    } else {
                        showError(response.error ?? "Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                        resendButton.isEnabled = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    showError(error.localizedDescription)
                    resendButton.isEnabled = true
                }
            }
        }
    }
    
    private func verifyCode(_ code: String) {
        guard !isLoading else { return }
        
        isLoading = true
        loadingIndicator.startAnimating()
        codeTextField.isEnabled = false
        codeTextField.resignFirstResponder()
        
        Task {
            do {
                guard let userAPI = BerifymeSDK.shared.user else {
                    await MainActor.run {
                        isLoading = false
                        loadingIndicator.stopAnimating()
                        codeTextField.isEnabled = true
                        onError("Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                let processedPhone = PhoneNumberProcessor.process(phoneNumber, countryIso2: defaultCountryIso2.lowercased())
                let response = try await userAPI.getUserByPhoneNumberAndVerifyCode(
                    phoneNumber: processedPhone,
                    code: code
                )
                
                guard let verifiedUser = response.user?.user else {
                    await MainActor.run {
                        isLoading = false
                        loadingIndicator.stopAnimating()
                        codeTextField.isEnabled = true
                        showError(response.error ?? "Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                // Align RN: try to enable biometrics after verification (non-blocking)
                BiometricsService.startBiometricsIfNeeded(phoneNumber: processedPhone)
                
                // best-effort: wallet (RN calls but does not block flow)
                if let walletAPI = BerifymeSDK.shared.wallet {
                    _ = try? await walletAPI.getWallet(phoneNumber: processedPhone)
                }
                
                // best-effort: checkDeviceId (match then AllSet) — align RN: use persisted deviceId
                if let sessionToken = token {
                    let deviceId = DeviceIdStore.getOrCreate()
                    let deviceRes = try? await userAPI.checkDeviceId(
                        phoneNumber: processedPhone,
                        deviceId: deviceId,
                        token: sessionToken
                    )
                    if let deviceUser = deviceRes?.user {
                        await MainActor.run {
                            isLoading = false
                            loadingIndicator.stopAnimating()
                            codeTextField.isEnabled = true
                            onComplete(deviceUser)
                        }
                        return
                    }
                }
                
                // vender decides which login to use
                let venderRes = try await userAPI.getUserVenderByPhone(phoneNumber: processedPhone, token: token)
                if let err = venderRes.error {
                    await MainActor.run {
                        isLoading = false
                        loadingIndicator.stopAnimating()
                        codeTextField.isEnabled = true
                        showError("Something went wrong, but we’re working on it. Please try again later or contact support for assistance.")
                    }
                    return
                }
                
                let loginStatus = PageStatus.loginStatus(forVendor: venderRes.vender ?? "")
                
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    codeTextField.isEnabled = true
                    
                    if let loginStatus = loginStatus {
                        mode = .welcomeBack(loginStatus: loginStatus, fullName: venderRes.fullName)
                        onUserVerified(verifiedUser)
                        updateModeUI()
                    } else {
                        // fallback: if backend returns no vender, use user's provider ids
                        if let clearId = verifiedUser.clearId, !clearId.isEmpty {
                            mode = .welcomeBack(loginStatus: .clearLogin, fullName: venderRes.fullName)
                            onUserVerified(verifiedUser)
                            updateModeUI()
                        } else if let incodeId = verifiedUser.incodeId, !incodeId.isEmpty {
                            mode = .welcomeBack(loginStatus: .incodeLogin, fullName: venderRes.fullName)
                            onUserVerified(verifiedUser)
                            updateModeUI()
                        } else {
                            showError("Something went wrong, but we’re working on it. Please try again later or contact support for assistance.")
                        }
                    }
                }
                
            } catch let apiError as APIError {
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    codeTextField.isEnabled = true
                    
                    var errorMessage = apiError.localizedDescription
                    if case .decodingError = apiError {
                        errorMessage = "Something went wrong, but we're working on it. Please try again later or contact support for assistance."
                    }
                    showError(errorMessage)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    codeTextField.isEnabled = true
                    showError("Something went wrong, but we’re working on it. Please try again later or contact support for assistance.")
                }
            }
        }
    }
    
    private func updateModeUI() {
        switch mode {
        case .codeEntry:
            welcomeContainerView.isHidden = true
            titleLabel.isHidden = false
            descriptionLabel.isHidden = false
            codeTextField.isHidden = false
            resendButton.isHidden = false
            errorLabel.isHidden = errorLabel.text?.isEmpty ?? true
        case .welcomeBack(_, let fullName):
            welcomeContainerView.isHidden = false
            titleLabel.isHidden = true
            descriptionLabel.isHidden = true
            codeTextField.isHidden = true
            resendButton.isHidden = true
            errorLabel.isHidden = true
            
            welcomeNameLabel.text = fullName ?? ""
        }
    }
    
    @objc private func takeSelfieTapped() {
        if case .welcomeBack(let loginStatus, _) = mode {
            onSelectLogin(loginStatus)
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        onError(message)
    }
}
