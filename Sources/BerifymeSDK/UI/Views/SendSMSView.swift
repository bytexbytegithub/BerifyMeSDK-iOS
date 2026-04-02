import UIKit

/// Log in / Sign Up view (send SMS verification code)
class SendSMSView: UIView {
    private let scrollView: UIScrollView
    private let contentView: UIView
    private enum Mode {
        case phoneEntry
        case welcomeBack(loginStatus: PageStatus, fullName: String?)
    }
    
    private let titleLabel: UILabel
    private let descriptionLabel: UILabel
    private let phoneLabel: UILabel
    private let phoneInputContainer: UIView
    private let countryCodeButton: UIButton
    private let nationalSeparator: UIView
    private let nationalPhoneTextField: UITextField
    private let legalLinksTextView: UITextView
    private let acceptButton: UIButton
    private let loadingIndicator: UIActivityIndicatorView
    private let footerView: FooterView
    private var tapToDismissRecognizer: UITapGestureRecognizer?
    private var keyboardObservers: [NSObjectProtocol] = []
    
    // Welcome back UI
    private let welcomeContainerView: UIView
    private let welcomeEmojiLabel: UILabel
    private let welcomeTitleLabel: UILabel
    private let welcomeNameLabel: UILabel
    private let welcomeDescriptionLabel: UILabel
    private let takeSelfieButton: UIButton
    
    private let token: String?
    private let initialPhoneNumber: String
    private let initialDefaultIso2: String
    private var selectedCountry: PhoneCountryOption
    private let onPhoneNumberChanged: (String) -> Void
    private let onSendCode: (String) -> Void
    private let onSelectLogin: ((PageStatus) -> Void)?
    
    private var mode: Mode = .phoneEntry
    private var isValid: Bool = false
    private var isLoading: Bool = false
    
    init(
        token: String?,
        phoneNumber: String,
        defaultCountryIso2: String = "US",
        onPhoneNumberChanged: @escaping (String) -> Void,
        onSendCode: @escaping (String) -> Void,
        onSelectLogin: ((PageStatus) -> Void)? = nil
    ) {
        self.token = token
        self.initialPhoneNumber = phoneNumber
        self.initialDefaultIso2 = defaultCountryIso2.uppercased()
        guard let def = PhoneCountryCatalog.option(forIso2: defaultCountryIso2) ?? PhoneCountryCatalog.option(forIso2: "US") else {
            fatalError("Phone country catalog must include US")
        }
        self.selectedCountry = def
        self.onPhoneNumberChanged = onPhoneNumberChanged
        self.onSendCode = onSendCode
        self.onSelectLogin = onSelectLogin
        
        scrollView = UIScrollView()
        contentView = UIView()
        titleLabel = UILabel()
        descriptionLabel = UILabel()
        phoneLabel = UILabel()
        phoneInputContainer = UIView()
        countryCodeButton = UIButton(type: .system)
        nationalSeparator = UIView()
        nationalPhoneTextField = UITextField()
        legalLinksTextView = UITextView()
        acceptButton = UIButton(type: .custom)
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        footerView = FooterView()
        
        welcomeContainerView = UIView()
        welcomeEmojiLabel = UILabel()
        welcomeTitleLabel = UILabel()
        welcomeNameLabel = UILabel()
        welcomeDescriptionLabel = UILabel()
        takeSelfieButton = UIButton(type: .system)
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func nationalPlaceholder() -> String {
        switch selectedCountry.iso2 {
        case "US", "CA":
            return "201 555 0123"
        case "TW":
            return "912 345 678"
        case "GB":
            return "7400 123456"
        default:
            return "Phone number"
        }
    }

    private func updateCountryButtonTitle() {
        let flag = PhoneCountryOption.flagEmoji(for: selectedCountry.iso2)
        // Title: widest case in bundled dial data is 3-digit calling code (no 4-digit codes in `PhoneCountryDialCodes`).
        let title: String
        if flag.isEmpty {
            title = "+\(selectedCountry.callingCode) ▾"
        } else {
            title = "\(flag) +\(selectedCountry.callingCode) ▾"
        }
        countryCodeButton.setTitle(title, for: .normal)
        let flagPrefix = flag.isEmpty ? "" : "\(flag) "
        countryCodeButton.accessibilityLabel = "\(flagPrefix)\(selectedCountry.localizedRegionName), +\(selectedCountry.callingCode)"
    }

    private func presentableViewController() -> UIViewController? {
        sequence(first: self as UIResponder?, next: { $0?.next }).first { $0 is UIViewController } as? UIViewController
    }

    @objc private func countryCodeTapped() {
        guard let host = presentableViewController() else { return }
        let picker = PhoneCountryPickerViewController(
            options: PhoneCountryCatalog.allOptionsSorted(),
            selectedIso2: selectedCountry.iso2
        ) { [weak self] option in
            self?.applySelectedCountry(option)
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.large()]
        }
        host.present(nav, animated: true)
    }

    private func applySelectedCountry(_ country: PhoneCountryOption) {
        selectedCountry = country
        updateCountryButtonTitle()
        nationalPhoneTextField.placeholder = nationalPlaceholder()
        phoneNumberChangedNational()
    }

    private func setupUI() {
        backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        titleLabel.text = "Log in / Sign Up"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        descriptionLabel.text = "We need your phone number to securely process your identity verification."
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = UIColor(white: 0.41, alpha: 1.0)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)

        phoneLabel.text = "Phone number"
        phoneLabel.font = .systemFont(ofSize: 16, weight: .medium)
        phoneLabel.textColor = .black
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneLabel)

        let fieldBg = UIColor(white: 0.95, alpha: 1.0)
        phoneInputContainer.backgroundColor = fieldBg
        phoneInputContainer.layer.cornerRadius = 12
        phoneInputContainer.layer.borderWidth = 2
        phoneInputContainer.layer.borderColor = fieldBg.cgColor
        phoneInputContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(phoneInputContainer)

        countryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        countryCodeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        countryCodeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        countryCodeButton.titleLabel?.minimumScaleFactor = 0.8
        countryCodeButton.titleLabel?.lineBreakMode = .byClipping
        countryCodeButton.setTitleColor(.black, for: .normal)
        countryCodeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 6)
        countryCodeButton.setContentHuggingPriority(.required, for: .horizontal)
        countryCodeButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        countryCodeButton.addTarget(self, action: #selector(countryCodeTapped), for: .touchUpInside)

        nationalSeparator.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        nationalSeparator.translatesAutoresizingMaskIntoConstraints = false

        nationalPhoneTextField.keyboardType = .phonePad
        nationalPhoneTextField.textContentType = .telephoneNumber
        nationalPhoneTextField.font = .systemFont(ofSize: 16, weight: .medium)
        nationalPhoneTextField.textColor = .black
        nationalPhoneTextField.backgroundColor = .clear
        nationalPhoneTextField.borderStyle = .none
        nationalPhoneTextField.autocorrectionType = .no
        nationalPhoneTextField.addTarget(self, action: #selector(phoneNumberChangedNational), for: .editingChanged)
        nationalPhoneTextField.translatesAutoresizingMaskIntoConstraints = false
        nationalPhoneTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nationalPhoneTextField.setContentCompressionResistancePriority(.required, for: .horizontal)

        phoneInputContainer.addSubview(countryCodeButton)
        phoneInputContainer.addSubview(nationalSeparator)
        phoneInputContainer.addSubview(nationalPhoneTextField)

        applyInitialNationalAndCountryFromProps()
        updateCountryButtonTitle()
        nationalPhoneTextField.placeholder = nationalPlaceholder()

        let legalText = "By tapping \"Accept & Continue\" I agree to Berify.me's Terms & Conditions, which contain a mandatory arbitration clause, class action waiver, and consent to e-sign, and Privacy Policy."
        let termsURL = URL(string: "https://berify.me/terms-conditions/")!
        let privacyURL = URL(string: "https://berify.me/privacy-policy/")!
        let attributed = NSMutableAttributedString(
            string: legalText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor(white: 0.41, alpha: 1.0)
            ]
        )
        if let r1 = legalText.range(of: "Terms & Conditions") {
            let nr1 = NSRange(r1, in: legalText)
            attributed.addAttribute(.link, value: termsURL, range: nr1)
            attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nr1)
        }
        if let r2 = legalText.range(of: "Privacy Policy") {
            let nr2 = NSRange(r2, in: legalText)
            attributed.addAttribute(.link, value: privacyURL, range: nr2)
            attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nr2)
        }
        legalLinksTextView.attributedText = attributed
        legalLinksTextView.font = .systemFont(ofSize: 12, weight: .medium)
        legalLinksTextView.textColor = UIColor(white: 0.41, alpha: 1.0)
        legalLinksTextView.isEditable = false
        legalLinksTextView.isScrollEnabled = false
        legalLinksTextView.backgroundColor = .clear
        legalLinksTextView.textContainerInset = .zero
        legalLinksTextView.textContainer.lineFragmentPadding = 0
        legalLinksTextView.delegate = self
        legalLinksTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(legalLinksTextView)

        acceptButton.setTitle("Accept & Continue", for: .normal)
        acceptButton.setTitle("Accept & Continue", for: .disabled)
        acceptButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        acceptButton.backgroundColor = .black
        acceptButton.layer.backgroundColor = UIColor.black.cgColor
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.setTitleColor(.white, for: .disabled)
        acceptButton.tintColor = .white
        acceptButton.layer.cornerRadius = 26
        acceptButton.clipsToBounds = true
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(acceptButton)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.addSubview(loadingIndicator)

        footerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(footerView)

        setupWelcomeBackUI()

        let topPadding: CGFloat = 20
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: topPadding),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: -16),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            phoneLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneInputContainer.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 8),
            phoneInputContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneInputContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneInputContainer.heightAnchor.constraint(equalToConstant: 48),

            countryCodeButton.leadingAnchor.constraint(equalTo: phoneInputContainer.leadingAnchor),
            countryCodeButton.topAnchor.constraint(equalTo: phoneInputContainer.topAnchor),
            countryCodeButton.bottomAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor),
            // Bundled metadata: calling codes are 1–3 digits only. Cap fits flag + "+888" + " ▾" + insets (~128pt).
            countryCodeButton.widthAnchor.constraint(lessThanOrEqualToConstant: 128),

            nationalSeparator.leadingAnchor.constraint(equalTo: countryCodeButton.trailingAnchor),
            nationalSeparator.topAnchor.constraint(equalTo: phoneInputContainer.topAnchor, constant: 10),
            nationalSeparator.bottomAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor, constant: -10),
            nationalSeparator.widthAnchor.constraint(equalToConstant: 1),

            nationalPhoneTextField.leadingAnchor.constraint(equalTo: nationalSeparator.trailingAnchor, constant: 6),
            nationalPhoneTextField.trailingAnchor.constraint(equalTo: phoneInputContainer.trailingAnchor, constant: -10),
            nationalPhoneTextField.centerYAnchor.constraint(equalTo: phoneInputContainer.centerYAnchor),

            legalLinksTextView.topAnchor.constraint(equalTo: phoneInputContainer.bottomAnchor, constant: 16),
            legalLinksTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            legalLinksTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            legalLinksTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            contentView.bottomAnchor.constraint(equalTo: legalLinksTextView.bottomAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            acceptButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            acceptButton.widthAnchor.constraint(equalToConstant: 200),
            acceptButton.heightAnchor.constraint(equalToConstant: 52),
            acceptButton.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -16),
            loadingIndicator.centerYAnchor.constraint(equalTo: acceptButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: acceptButton.trailingAnchor, constant: -20),

            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            footerView.heightAnchor.constraint(equalToConstant: 44),
            
            welcomeContainerView.topAnchor.constraint(equalTo: topAnchor),
            welcomeContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            welcomeContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            welcomeContainerView.bottomAnchor.constraint(equalTo: footerView.topAnchor)
        ])
        
        tapToDismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapToDismissRecognizer?.cancelsTouchesInView = false
        addGestureRecognizer(tapToDismissRecognizer!)

        setupKeyboardObservers()
        recomputeProcessedAndNotifyIfNeeded(shouldNotifyParent: true)
        updateModeUI()
        updateButtonState()
    }

    private func applyInitialNationalAndCountryFromProps() {
        let processed = PhoneNumberProcessor.process(initialPhoneNumber, countryIso2: initialDefaultIso2.lowercased())
        if let parsed = PhoneCountryCatalog.parse(fullInternationalDigits: processed, preferredIso2: initialDefaultIso2) {
            selectedCountry = parsed.country
            nationalPhoneTextField.text = parsed.nationalDigits
        } else if processed.isEmpty {
            nationalPhoneTextField.text = ""
        } else {
            let digits = processed
            if digits.hasPrefix(selectedCountry.callingCode) {
                nationalPhoneTextField.text = String(digits.dropFirst(selectedCountry.callingCode.count))
            } else {
                nationalPhoneTextField.text = digits
            }
        }
    }

    private func recomputeProcessedAndNotifyIfNeeded(shouldNotifyParent: Bool) {
        let natDigits = (nationalPhoneTextField.text ?? "").filter { $0.isNumber }
        let full = selectedCountry.callingCode + natDigits
        var processed = PhoneNumberProcessor.process(full, countryIso2: selectedCountry.iso2.lowercased())

        if let repr = PhoneCountryCatalog.parse(fullInternationalDigits: processed, preferredIso2: selectedCountry.iso2) {
            if repr.country.iso2 != selectedCountry.iso2 {
                selectedCountry = repr.country
                updateCountryButtonTitle()
                nationalPhoneTextField.placeholder = nationalPlaceholder()
            }
            let newNat = repr.nationalDigits
            if newNat != natDigits {
                nationalPhoneTextField.text = newNat
                if let end = nationalPhoneTextField.position(from: nationalPhoneTextField.beginningOfDocument, offset: newNat.count) {
                    nationalPhoneTextField.selectedTextRange = nationalPhoneTextField.textRange(from: end, to: end)
                }
                processed = PhoneNumberProcessor.process(selectedCountry.callingCode + newNat, countryIso2: selectedCountry.iso2.lowercased())
            }
        }

        if shouldNotifyParent {
            onPhoneNumberChanged(processed)
        }
        isValid = processed.count >= 8
    }
    
    private func setupKeyboardObservers() {
        let show = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.keyboardWillShow(note)
        }
        let hide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.keyboardWillHide()
        }
        keyboardObservers = [show, hide]
    }
    
    private func keyboardWillShow(_ note: Notification) {
        guard case .phoneEntry = mode,
              let userInfo = note.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = frame.height
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = inset
        scrollView.verticalScrollIndicatorInsets = inset
        DispatchQueue.main.async { [weak self] in
            self?.scrollToShowLegalAndButton()
        }
    }
    
    private func keyboardWillHide() {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }
    
    private func scrollToShowLegalAndButton() {
        guard case .phoneEntry = mode else { return }
        layoutIfNeeded()
        let rect = legalLinksTextView.convert(legalLinksTextView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -24), animated: true)
    }
    
    @objc private func dismissKeyboard() {
        endEditing(true)
    }
    
    private func setupWelcomeBackUI() {
        welcomeContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(welcomeContainerView)

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
    
    private func updateModeUI() {
        switch mode {
        case .phoneEntry:
            scrollView.isHidden = false
            titleLabel.isHidden = false
            descriptionLabel.isHidden = false
            phoneLabel.isHidden = false
            phoneInputContainer.isHidden = false
            legalLinksTextView.isHidden = false
            acceptButton.isHidden = false
            footerView.isHidden = false
            welcomeContainerView.isHidden = true
        case .welcomeBack(_, let fullName):
            scrollView.isHidden = true
            titleLabel.isHidden = true
            descriptionLabel.isHidden = true
            phoneLabel.isHidden = true
            phoneInputContainer.isHidden = true
            legalLinksTextView.isHidden = true
            acceptButton.isHidden = true
            footerView.isHidden = false
            welcomeContainerView.isHidden = false
            welcomeNameLabel.text = fullName ?? ""
        }
    }
    
    private func updateButtonState() {
        let enabled = isValid && !isLoading
        acceptButton.isEnabled = enabled
        acceptButton.alpha = 1.0
        let bgColor: UIColor = enabled ? .black : UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 0.39)
        acceptButton.backgroundColor = bgColor
        acceptButton.layer.backgroundColor = bgColor.cgColor
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.setTitleColor(.white, for: .disabled)
    }
    
    @objc private func phoneNumberChangedNational() {
        recomputeProcessedAndNotifyIfNeeded(shouldNotifyParent: true)
        updateButtonState()
    }
    
    @objc private func acceptTapped() {
        guard isValid, !isLoading else { return }
        let natDigits = (nationalPhoneTextField.text ?? "").filter { $0.isNumber }
        let full = selectedCountry.callingCode + natDigits
        let processed = PhoneNumberProcessor.process(full, countryIso2: selectedCountry.iso2.lowercased())
        guard processed.count >= 8 else { return }
        
        isLoading = true
        loadingIndicator.startAnimating()
        acceptButton.isEnabled = false
        updateButtonState()
        
        onSendCode(processed)
    }
    
    @objc private func takeSelfieTapped() {
        if case .welcomeBack(let loginStatus, _) = mode {
            onSelectLogin?(loginStatus)
        }
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        updateButtonState()
    }
    
    func showWelcomeBack(loginStatus: PageStatus, fullName: String?) {
        mode = .welcomeBack(loginStatus: loginStatus, fullName: fullName)
        updateModeUI()
    }
}

extension SendSMSView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
