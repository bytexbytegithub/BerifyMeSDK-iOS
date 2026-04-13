import UIKit

/// Verify new user view
class VerifyNewUserView: UIView {
    private let codeTextField: UITextField
    private let resendButton: UIButton
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel
    private let errorLabel: UILabel
    private let loadingIndicator: UIActivityIndicatorView
    private let infoContainerView: UIView
    private let backButton: UIButton
    private let footerView: FooterView
    
    private let token: String?
    private let phoneNumber: String
    private let defaultCountryIso2: String
    private let onComplete: (User) -> Void
    private let onError: (String) -> Void
    private let onBack: (() -> Void)?
    
    private var countdown: Int = 60
    private var countdownTimer: Timer?
    private var isLoading: Bool = false
    
    init(
        token: String?,
        phoneNumber: String,
        defaultCountryIso2: String = "US",
        onComplete: @escaping (User) -> Void,
        onError: @escaping (String) -> Void,
        onBack: (() -> Void)? = nil
    ) {
        self.token = token
        self.phoneNumber = phoneNumber
        self.defaultCountryIso2 = defaultCountryIso2.uppercased()
        self.onComplete = onComplete
        self.onError = onError
        self.onBack = onBack
        
        codeTextField = UITextField()
        resendButton = UIButton(type: .system)
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        errorLabel = UILabel()
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        infoContainerView = UIView()
        backButton = UIButton(type: .system)
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
        if onBack != nil {
            let backImageView = UIImageView()
            if let imageURL = URL(string: "https://idv.berify.me/arrowLeft.png") {
                URLSession.shared.dataTask(with: imageURL) { data, _, _ in
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
        
        // Title
        titleLabel.text = "Sign Up"
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
        
        // Verification code input
        codeTextField.placeholder = "Enter code"
        codeTextField.keyboardType = .numberPad
        codeTextField.textContentType = .oneTimeCode
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
        
        // Resend button
        resendButton.setTitle("Resend code", for: .normal)
        resendButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        resendButton.setTitleColor(UIColor(red: 0.31, green: 0.27, blue: 0.90, alpha: 1.0), for: .normal)
        resendButton.setTitleColor(.gray, for: .disabled)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        resendButton.isEnabled = false
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resendButton)
        
        // Error label (align RN: textAlign: 'right')
        errorLabel.font = .systemFont(ofSize: 12, weight: .medium)
        errorLabel.textColor = UIColor(red: 1, green: 84/255, blue: 84/255, alpha: 1) // #FF5454, align RN
        errorLabel.textAlignment = .right
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorLabel)
        
        // Info container (2 Easy Steps)
        infoContainerView.backgroundColor = UIColor(red: 0.90, green: 0.97, blue: 0.99, alpha: 1.0)
        infoContainerView.layer.cornerRadius = 16
        infoContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoContainerView)
        
        footerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerView)
        
        setupInfoContainer()
        
        // Constraints
        var constraints: [NSLayoutConstraint] = []
        
        // Align RN: ph={8}, reduce spacing between back button and title
        if let _ = onBack {
            constraints.append(contentsOf: [
                backButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44)
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
            
            infoContainerView.topAnchor.constraint(equalTo: resendButton.bottomAnchor, constant: 32),
            infoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            infoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            // Blue block height by content; footer fixed at bottom
            footerView.topAnchor.constraint(greaterThanOrEqualTo: infoContainerView.bottomAnchor, constant: 16),
            
            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            footerView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupInfoContainer() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title row
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.spacing = 10
        titleStack.alignment = .center
        
        let iconImageView = UIImageView()
        // Align RN SDK: use blueInfo.png
        if let imageURL = URL(string: "https://idv.berify.me/blueInfo.png") {
            URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    iconImageView.image = image
                }
            }.resume()
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "2 Easy Steps"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.00, green: 0.26, blue: 0.38, alpha: 1.0)
        
        titleStack.addArrangedSubview(iconImageView)
        titleStack.addArrangedSubview(titleLabel)
        
        // Steps list (align RN: pl={36}, 36pt left indent)
        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 8
        
        let step1Label = UILabel()
        step1Label.text = "1. Choose verification provider"
        step1Label.font = .systemFont(ofSize: 14, weight: .medium)
        step1Label.textColor = UIColor(red: 0.00, green: 0.26, blue: 0.38, alpha: 1.0)
        
        let step2Label = UILabel()
        step2Label.text = "2. Upload your ID or Passport and Take a Selfie"
        step2Label.font = .systemFont(ofSize: 14, weight: .medium)
        step2Label.textColor = UIColor(red: 0.00, green: 0.26, blue: 0.38, alpha: 1.0)
        
        stepsStack.addArrangedSubview(step1Label)
        stepsStack.addArrangedSubview(step2Label)
        
        let stepsRowStack = UIStackView()
        stepsRowStack.axis = .horizontal
        stepsRowStack.spacing = 0
        let stepsSpacer = UIView()
        stepsSpacer.translatesAutoresizingMaskIntoConstraints = false
        stepsSpacer.widthAnchor.constraint(equalToConstant: 20).isActive = true // 16 + 20 = 36 from container
        stepsRowStack.addArrangedSubview(stepsSpacer)
        stepsRowStack.addArrangedSubview(stepsStack)
        
        // Closing text
        let congratsLabel = UILabel()
        congratsLabel.text = "Congrats, you're Berified!"
        congratsLabel.font = .systemFont(ofSize: 16, weight: .bold)
        congratsLabel.textColor = UIColor(red: 0.00, green: 0.26, blue: 0.38, alpha: 1.0)
        
        stackView.addArrangedSubview(titleStack)
        stackView.addArrangedSubview(stepsRowStack)
        stackView.addArrangedSubview(congratsLabel)
        
        infoContainerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -16)
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
    
    @objc private func codeChanged() {
        guard let code = codeTextField.text else { return }
        
        // Limit to 6 digits
        let filteredCode = String(code.prefix(6).filter { $0.isNumber })
        if filteredCode != code {
            codeTextField.text = filteredCode
        }
        
        // Auto-verify: submit when 6 digits entered
        if filteredCode.count == 6 && !isLoading {
            verifyCode(filteredCode)
        }
        
        // Update error display
        if errorLabel.isHidden == false && !filteredCode.isEmpty {
            errorLabel.isHidden = true
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
                
                await MainActor.run {
                    isLoading = false
                    loadingIndicator.stopAnimating()
                    codeTextField.isEnabled = true
                    
                    if let userWithCredentials = response.user {
                        // After verification, align RN: try to enable biometrics (non-blocking)
                        BiometricsService.startBiometricsIfNeeded(phoneNumber: processedPhone)
                        
                        // Verification success, go to Incode (skip Vender selection)
                        // Note: onComplete is handled by BerifymeModalViewController
                        // It should go to .incodeOnBoarding not .vender
                        onComplete(userWithCredentials.user)
                    } else {
                        let errorMsg = response.error ?? "Something went wrong, but we're working on it. Please try again later or contact support for assistance."
                        showError(errorMsg)
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
                    showError("Something went wrong, but we're working on it. Please try again later or contact support for assistance.")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        onError(message)
    }
}
