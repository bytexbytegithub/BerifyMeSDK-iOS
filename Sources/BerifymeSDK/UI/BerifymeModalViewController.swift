import UIKit

/// Berify.me Modal main view controller
public class BerifymeModalViewController: UIViewController {
    // MARK: - Properties
    
    private let apiKeyId: String
    private let secretKey: String
    private let environment: Environment
    private let verifiedExternalPhoneNumber: String?
    /// Incode 介面語系（en | zh-TW | mix）；nil 時依裝置慣用語系決定預設（繁中 → zh-TW，其餘 → en）
    private let locale: String?
    private let onUpdate: ((UpdateData) -> Void)?
    private let onComplete: ((String?) -> Void)?
    
    private var sessionToken: String?
    private var currentUser: User?
    private var currentPageStatus: PageStatus = .loading
    private var errorMessage: String?
    private var phoneNumber: String = ""
    private var processedPhoneNumber: String?
    /// When false, success flow: get redirect URL and open it, or get token and complete without showing AllSetView (align with RNSDK).
    private var useDefaultSuccessPageApp: Bool = true
    /// From `checkToken` `configuration.defaultPhoneCountryCode`; invalid / nil → `"US"` (align WebSDK `resolveReactPhoneInput2Country`).
    private var defaultPhoneCountryIso2: String = "US"
    
    private var apiClient: APIClient?
    private var authAPI: AuthAPI?
    private var userAPI: UserAPI?
    private var toolsAPI: ToolsAPI?
    private var clearAPI: ClearAPI?
    private var incodeAPI: IncodeAPI?
    
    // MARK: - UI Components
    
    private var containerView: UIView!
    private var containerViewBottomConstraint: NSLayoutConstraint?
    private var currentContentView: UIView?
    
    // MARK: - Initialization
    
    public init(
        apiKeyId: String,
        secretKey: String,
        environment: Environment,
        verifiedExternalPhoneNumber: String? = nil,
        locale: String? = nil,
        onUpdate: ((UpdateData) -> Void)? = nil,
        onComplete: ((String?) -> Void)? = nil
    ) {
        self.apiKeyId = apiKeyId
        self.secretKey = secretKey
        self.environment = environment
        self.verifiedExternalPhoneNumber = verifiedExternalPhoneNumber
        self.locale = locale
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardAvoidance()
        initializeAPI()
        createSessionToken()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        removeKeyboardAvoidance()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Identity Verification"

        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        let bottom = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomConstraint = bottom
        let topInset: CGFloat = 20
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom
        ])
    }
    
    private func setupKeyboardAvoidance() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardAvoidance() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ n: Notification) {
        guard let userInfo = n.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let height = frame.height
        containerViewBottomConstraint?.constant = -height
        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    @objc private func keyboardWillHide(_ n: Notification) {
        guard let userInfo = n.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        containerViewBottomConstraint?.constant = 0
        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    private func initializeAPI() {
        let baseURL = environment.backendDomain
        apiClient = APIClient(baseURL: baseURL)
        
        if let client = apiClient {
            authAPI = AuthAPI(client: client)
            userAPI = UserAPI(client: client)
            toolsAPI = ToolsAPI(client: client)
            clearAPI = ClearAPI(client: client)
            incodeAPI = IncodeAPI(client: client)
        }
    }
    
    // MARK: - API Methods
    
    private func createSessionToken() {
        Task {
            let ok = await performCreateSessionAndResume()
            await MainActor.run {
                if !ok {
                    self.updatePageStatus(.loading)
                }
            }
        }
    }
    
    /// 建立新 session token、更新 configuration，並依 `verifiedExternalPhoneNumber` 導向起始頁。
    /// - Returns: 是否成功取得 token 並完成導向
    private func performCreateSessionAndResume() async -> Bool {
        guard let toolsAPI = toolsAPI else { return false }
        do {
            let response = try await toolsAPI.createSessionTokenWithoutRedirectUrl(
                apiKeyId: apiKeyId,
                secretKey: secretKey
            )
            guard let newToken = response.sessionToken else {
                await MainActor.run {
                    self.errorMessage = response.error ?? "Failed to create session"
                }
                return false
            }
            await MainActor.run {
                self.sessionToken = newToken
                self.errorMessage = nil
            }
            await fetchResultPageConfiguration()
            await MainActor.run {
                self.handleInitialPageStatus()
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    /// 與後端 `checkToken` 一致：此類錯誤應重新建立 session，而非僅返回上一頁
    private static func isSessionExpiredError(_ message: String) -> Bool {
        let m = message.lowercased()
        return m.contains("session expired") || m.contains("session token is inactive")
    }
    
    /// Fetch company configuration (e.g. useDefaultSuccessPageApp) after session is created.
    private func fetchResultPageConfiguration() async {
        guard let token = sessionToken, let toolsAPI = toolsAPI else { return }
        do {
            let response = try await toolsAPI.checkThirdPartyVerificationToken(token: token)
            await MainActor.run {
                self.useDefaultSuccessPageApp = response.configuration?.useDefaultSuccessPageApp ?? true
                self.defaultPhoneCountryIso2 = Self.resolvedDefaultPhoneCountryIso2(
                    from: response.configuration?.defaultPhoneCountryCode
                )
            }
        } catch {
            // Keep default (true): show AllSetView on success
        }
    }

    private func handleInitialPageStatus() {
        if let verifiedPhone = verifiedExternalPhoneNumber {
            let processed = PhoneNumberProcessor.process(verifiedPhone, countryIso2: phoneProcessorCountryIso2)
            processedPhoneNumber = processed
            updatePageStatus(.verifiedExternalPhoneNumber)
        } else {
            updatePageStatus(.sendSNS)
        }
    }
    
    // MARK: - Page Management
    
    private func expandModalToFullScreenIfNeeded() {
        guard #available(iOS 15.0, *) else { return }
        guard let nav = navigationController,
              let sheet = nav.sheetPresentationController else { return }
        if #available(iOS 16.0, *) {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .large
            }
        }
    }
    
    private func isFullScreenFlow(_ status: PageStatus) -> Bool {
        switch status {
        case .clearOnboarding, .clearLogin,
             .incodeOnBoarding, .incodeLogin,
             .authidLogin, .authIdOnboarding,
             .sumsubLogin, .sumsubOnBoarding,
             .veriffLogin, .veriffOnBoarding,
             .yotiLogin, .yotiOnBoarding:
            return true
        default:
            return false
        }
    }
    
    private func updatePageStatus(_ status: PageStatus) {
        currentPageStatus = status
        
        if isFullScreenFlow(status) {
            expandModalToFullScreenIfNeeded()
        }
        
        let updateData = UpdateData(
            page: UpdateData.PageInfo(pageName: status.pageName),
            message: errorMessage
        )
        onUpdate?(updateData)
        updateContentView()
    }
    
    private func updateContentView() {
        currentContentView?.removeFromSuperview()
        currentContentView = nil
        
        if let error = errorMessage {
            showErrorView(message: error)
        } else {
            switch currentPageStatus {
            case .loading:
                showLoadingView()
            case .sendSNS:
                showSendSMSView()
            case .verifiedExternalPhoneNumber:
                showVerifiedExternalPhoneNumberView()
            case .verifyNewUser:
                showVerifyNewUserView()
            case .vender:
                showVendorSelectionView()
            case .verifyUser:
                showVerifyUserView()
            case .clearOnboarding, .clearLogin:
                showClearView()
            case .incodeOnBoarding, .incodeLogin:
                showIncodeView()
            case .clearLoginAllSet, .clearOnboardingAllSet:
                showAllSetView()
            case .authidLogin, .authIdOnboarding, .idOrPassport,
                 .sumsubLogin, .sumsubOnBoarding,
                 .veriffLogin, .veriffOnBoarding,
                 .yotiLogin, .yotiOnBoarding:
                showErrorView(message: "This verification provider flow is not yet supported (\(currentPageStatus.pageName)).")
            case .allSet:
                showAllSetView()
            default:
                showLoadingView()
            }
        }
    }
    
    // MARK: - View Controllers
    
    private func showLoadingView() {
        let loadingView = LoadingView()
        addContentView(loadingView)
    }
    
    private func showErrorView(message: String) {
        let errorView = ErrorView(message: message) { [weak self] in
            guard let self = self else { return }
            if Self.isSessionExpiredError(message) {
                self.onUpdate?(
                    UpdateData(
                        page: UpdateData.PageInfo(pageName: "SessionExpiredRetry"),
                        message: UpdateData.sessionExpiredRetryMessage,
                        sessionExpiredRetry: true
                    )
                )
                self.currentUser = nil
                self.phoneNumber = ""
                self.processedPhoneNumber = nil
                self.errorMessage = nil
                self.updatePageStatus(.loading)
                Task { [weak self] in
                    guard let self = self else { return }
                    let ok = await self.performCreateSessionAndResume()
                    await MainActor.run {
                        if !ok {
                            self.updatePageStatus(.loading)
                        }
                    }
                }
            } else {
                self.errorMessage = nil
                self.updatePageStatus(self.fallbackPageForError())
            }
        }
        addContentView(errorView)
    }
    
    private func showSendSMSView() {
        let sendSMSView = SendSMSView(
            token: sessionToken,
            phoneNumber: phoneNumber,
            defaultCountryIso2: defaultPhoneCountryIso2,
            onPhoneNumberChanged: { [weak self] phone in
                self?.phoneNumber = phone
            },
            onSendCode: { [weak self] phone in
                self?.handleSendSMS(phone: phone)
            },
            onSelectLogin: { [weak self] loginStatus in
                self?.updatePageStatus(loginStatus)
            }
        )
        addContentView(sendSMSView)
    }
    
    private func showVerifiedExternalPhoneNumberView() {
        guard let phone = processedPhoneNumber else { return }
        let view = VerifiedExternalPhoneNumberView(
            token: sessionToken,
            phoneNumber: phone,
            onComplete: { [weak self] user in
                self?.currentUser = user
                if let vender = user.clearId, !vender.isEmpty {
                    self?.updatePageStatus(.clearLogin)
                } else if let incodeId = user.incodeId, !incodeId.isEmpty {
                    self?.updatePageStatus(.incodeLogin)
                } else {
                    self?.updatePageStatus(.incodeOnBoarding)
                }
            },
            onSelectLogin: { [weak self] loginStatus in
                // Enter corresponding flow based on vender-selected login page
                self?.updatePageStatus(loginStatus)
            },
            onUserVerified: { [weak self] user in
                self?.currentUser = user
            },
            onError: { [weak self] error in
                self?.errorMessage = error
                self?.updatePageStatus(self?.fallbackPageForError() ?? .sendSNS)
            }
        )
        addContentView(view)
    }
    
    private func showVerifyNewUserView() {
        let view = VerifyNewUserView(
            token: sessionToken,
            phoneNumber: phoneNumber,
            defaultCountryIso2: defaultPhoneCountryIso2,
            onComplete: { [weak self] user in
                self?.currentUser = user
                self?.updatePageStatus(.incodeOnBoarding)
            },
            onError: { [weak self] error in
                self?.errorMessage = error
                self?.updatePageStatus(.sendSNS)
            },
            onBack: { [weak self] in
                self?.updatePageStatus(.sendSNS)
            }
        )
        addContentView(view)
    }
    
    private func showVendorSelectionView() {
        guard let user = currentUser else { return }
        let view = VendorSelectionView(
            user: user,
            onSelectVendor: { [weak self] vendor in
                self?.handleVendorSelection(vendor: vendor)
            }
        )
        addContentView(view)
    }
    
    private func showVerifyUserView() {
        let view = VerifyUserView(
            token: sessionToken,
            phoneNumber: processedPhoneNumber ?? phoneNumber,
            defaultCountryIso2: defaultPhoneCountryIso2,
            onComplete: { [weak self] user in
                self?.currentUser = user
                self?.updatePageStatus(.allSet)
            },
            onSelectLogin: { [weak self] loginStatus in
                self?.updatePageStatus(loginStatus)
            },
            onUserVerified: { [weak self] user in
                self?.currentUser = user
            },
            onError: { [weak self] error in
                self?.errorMessage = error
                self?.updatePageStatus(.sendSNS)
            },
            onBack: { [weak self] in
                self?.updatePageStatus(.sendSNS)
            }
        )
        addContentView(view)
    }
    
    private func showClearView() {
        guard let user = currentUser, let token = sessionToken else { return }
        let isOnboarding = currentPageStatus == .clearOnboarding
        
        Task {
            let permissionResults = await PermissionService.requestAllPermissions()
            
            await MainActor.run {
                if !permissionResults.camera {
                    self.errorMessage = "Camera permission is required for verification. Please enable in Settings > Privacy & Security > Camera."
                    // No vendor selection: external-phone → verifiedExternalPhoneNumber; else → sendSNS. User can enable permission and retry.
                    self.updatePageStatus(self.fallbackPageForError())
                    return
                }
                
                if !permissionResults.photoLibrary {
                    self.errorMessage = "Photo library permission is required to upload documents. Please enable in Settings > Privacy & Security > Photos."
                    // No vendor selection: external-phone → verifiedExternalPhoneNumber; else → sendSNS. User can enable permission and retry.
                    self.updatePageStatus(self.fallbackPageForError())
                    return
                }
                
                let view = ClearWebView(
                    user: user,
                    token: token,
                    environment: environment,
                    isOnboarding: isOnboarding,
                    onComplete: { [weak self] in
                        self?.updatePageStatus(.allSet)
                    },
                    onError: { [weak self] error in
                        self?.errorMessage = error
                        // No vendor selection: external-phone → verifiedExternalPhoneNumber; else → sendSNS. User can retry.
                        self?.updatePageStatus(self?.fallbackPageForError() ?? .sendSNS)
                    }
                )
                self.addContentView(view)
            }
        }
    }
    
    private func showIncodeView() {
        guard let user = currentUser, let token = sessionToken else {
            errorMessage = "Something went wrong, but we're working on it. Please try again later or contact support for assistance."
            updatePageStatus(fallbackPageForError())
            return
        }
        let isOnboarding = currentPageStatus == .incodeOnBoarding
        let view = IncodeWebView(
            user: user,
            token: token,
            environment: environment,
            isOnboarding: isOnboarding,
            locale: locale,
            onComplete: { [weak self] updatedUser in
                if let updatedUser = updatedUser {
                    self?.currentUser = updatedUser
                }
                self?.updatePageStatus(.allSet)
            },
            onError: { [weak self] error in
                self?.errorMessage = error
                // No vendor selection: external-phone → verifiedExternalPhoneNumber; else → sendSNS. User can retry.
                self?.updatePageStatus(self?.fallbackPageForError() ?? .sendSNS)
            }
        )
        addContentView(view)
    }
    
    private func showAllSetView() {
        if !useDefaultSuccessPageApp {
            // No default success page: get redirect URL and open it, or get token and complete (align with RNSDK).
            addContentView(LoadingView())
            performRedirectOrTokenFlow()
            return
        }

        let view = AllSetView(
            user: currentUser,
            token: sessionToken,
            onComplete: { [weak self] token in
                self?.onComplete?(token)
                self?.dismiss(animated: true)
            }
        )
        addContentView(view)

        if let user = currentUser {
            Task {
                let deviceId = DeviceIdStore.getOrCreate()
                if let api = self.userAPI {
                    _ = try? await api.uploadDeviceId(id: user.id, deviceId: deviceId, token: self.sessionToken)
                }
            }
        }
    }

    /// When default success page is off: get redirect URL and open it, or get generalVerificationToken and complete.
    private func performRedirectOrTokenFlow() {
        guard let toolsAPI = toolsAPI,
              let sessionToken = sessionToken,
              let userId = currentUser?.id else {
            errorMessage = "Something went wrong. Please try again."
            updatePageStatus(.loading)
            return
        }
        Task {
            do {
                let redirectRes = try await toolsAPI.getRedirectUrl(userId: userId, token: sessionToken, client: "app")
                await MainActor.run {
                    if let urlString = redirectRes.redirectUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                        dismiss(animated: true)
                        return
                    }
                    // No redirect URL: get token and complete without showing AllSetView
                    self.finishWithGeneralVerificationToken()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.updatePageStatus(.loading)
                }
            }
        }
    }

    private func finishWithGeneralVerificationToken() {
        guard let toolsAPI = toolsAPI,
              let sessionToken = sessionToken,
              let userId = currentUser?.id else {
            errorMessage = "Something went wrong. Please try again."
            updatePageStatus(.loading)
            return
        }
        Task {
            do {
                let res = try await toolsAPI.getGeneralVerificationToken(userId: userId, token: sessionToken)
                await MainActor.run {
                    if let token = res.generalVerificationToken {
                        onComplete?(token)
                        dismiss(animated: true)
                    } else {
                        errorMessage = res.error ?? "Could not complete verification."
                        updatePageStatus(.loading)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.updatePageStatus(.loading)
                }
            }
        }
    }
    
    private func addContentView(_ contentView: UIView) {
        currentContentView = contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    /// When permission/error forces a step back: external-phone users return to verified-phone screen; others to sendSNS (phone entry).
    private func fallbackPageForError() -> PageStatus {
        return verifiedExternalPhoneNumber != nil ? .verifiedExternalPhoneNumber : .sendSNS
    }

    private static func resolvedDefaultPhoneCountryIso2(from raw: String?) -> String {
        let c = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if c.count == 2, c.range(of: "^[a-z]{2}$", options: .regularExpression) != nil {
            return c.uppercased()
        }
        return "US"
    }

    private var phoneProcessorCountryIso2: String { defaultPhoneCountryIso2.lowercased() }
    
    private func handleSendSMS(phone: String) {
        guard let authAPI = authAPI, let userAPI = userAPI else { return }
        
        let processed = PhoneNumberProcessor.process(phone, countryIso2: phoneProcessorCountryIso2)
        let sendView = currentContentView as? SendSMSView
        Task { @MainActor in
            sendView?.setLoading(true)
        }
        
        Task {
            do {
                let venderRes = try await userAPI.getUserVenderByPhone(phoneNumber: processed, token: sessionToken)
                if let err = venderRes.error, !err.isEmpty {
                    await MainActor.run {
                        (self.currentContentView as? SendSMSView)?.setLoading(false)
                        self.errorMessage = "Something went wrong, but we’re working on it. Please try again later or contact support for assistance."
                        self.updatePageStatus(.sendSNS)
                    }
                    return
                }
                
                if let bioAPI = BerifymeSDK.shared.biometrics,
                   let publicKey = BiometricsService.storedPublicKey(phoneNumber: processed) {
                    let bioRes = try await bioAPI.checkBiometricsStatus(phoneNumber: processed, publicKey: publicKey)
                    if bioRes.status == .match, let bioUser = bioRes.user {
                        if let walletAPI = BerifymeSDK.shared.wallet {
                            _ = try? await walletAPI.getWallet(phoneNumber: processed)
                        }
                        
                        if let token = self.sessionToken {
                            let deviceId = DeviceIdStore.getOrCreate()
                            let deviceRes = try? await userAPI.checkDeviceId(phoneNumber: processed, deviceId: deviceId, token: token)
                            if let deviceUser = deviceRes?.user {
                                await MainActor.run {
                                    (self.currentContentView as? SendSMSView)?.setLoading(false)
                                    self.currentUser = deviceUser
                                    self.updatePageStatus(.allSet)
                                }
                                return
                            }
                        }
                        
                        let loginStatus = PageStatus.loginStatus(forVendor: venderRes.vender ?? "")
                        
                        await MainActor.run {
                            (self.currentContentView as? SendSMSView)?.setLoading(false)
                            self.currentUser = bioUser
                            if let loginStatus {
                                (self.currentContentView as? SendSMSView)?.showWelcomeBack(loginStatus: loginStatus, fullName: venderRes.fullName)
                            } else {
                                self.errorMessage = "Try again later or choose a different verification provider to proceed."
                                self.updatePageStatus(.sendSNS)
                            }
                        }
                        return
                    }
                }
                
                let response = try await authAPI.sendPhoneNumberCode(phoneNumber: processed, token: sessionToken)
                await MainActor.run {
                    (self.currentContentView as? SendSMSView)?.setLoading(false)
                    if response.success == true {
                        self.phoneNumber = processed
                        self.processedPhoneNumber = processed
                        if let vender = venderRes.vender, !vender.isEmpty {
                            self.updatePageStatus(.verifyUser)
                        } else {
                            self.updatePageStatus(.verifyNewUser)
                        }
                    } else {
                        self.errorMessage = response.error ?? "Something went wrong, but we’re working on it. Please try again later or contact support for assistance."
                        self.updatePageStatus(.sendSNS)
                    }
                }
            } catch {
                await MainActor.run {
                    (self.currentContentView as? SendSMSView)?.setLoading(false)
                    self.errorMessage = error.localizedDescription
                    self.updatePageStatus(.sendSNS)
                }
            }
        }
    }
    
    private func handleVendorSelection(vendor: String) {
        switch vendor.lowercased() {
        case "authid":
            updatePageStatus(.authIdOnboarding)
        case "clear":
            updatePageStatus(.clearOnboarding)
        case "incode":
            updatePageStatus(.incodeOnBoarding)
        default:
            errorMessage = "Unsupported verification provider"
            // No vendor selection: external-phone → verifiedExternalPhoneNumber; else → sendSNS.
            updatePageStatus(fallbackPageForError())
        }
    }
}
