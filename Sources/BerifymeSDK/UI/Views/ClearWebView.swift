import UIKit
import WebKit

/// Clear WebView view
class ClearWebView: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    private let webView: WKWebView
    private let loadingIndicator: UIActivityIndicatorView
    
    private let user: User
    private let token: String
    private let environment: Environment
    private let isOnboarding: Bool
    private let onComplete: () -> Void
    private let onError: (String) -> Void
    
    private var sessionId: String?
    
    init(
        user: User,
        token: String,
        environment: Environment,
        isOnboarding: Bool,
        onComplete: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) {
        // Set all properties first
        self.user = user
        self.token = token
        self.environment = environment
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
        self.onError = onError
        
        // Create config (do not add message handlers yet)
        let config = WKWebViewConfiguration()
        
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        if #available(iOS 15.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        config.applicationNameForUserAgent = "BerifymeSDK"
        webView = WKWebView(frame: .zero, configuration: config)
        loadingIndicator = UIActivityIndicatorView(style: .large)
        
        super.init(frame: .zero)
        let userContentController = WKUserContentController()
        let script = """
        (function() {
            if (!window.ReactNativeWebView) {
                window.ReactNativeWebView = {};
            }
            var originalRNPostMessage = window.ReactNativeWebView.postMessage;
            window.ReactNativeWebView.postMessage = function(data) {
                var messageData;
                if (typeof data === 'string') {
                    try {
                        messageData = JSON.parse(data);
                    } catch(e) {
                        messageData = { event: 'message', data: data };
                    }
                } else {
                    messageData = data;
                }
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.berifymeMessageHandler) {
                    window.webkit.messageHandlers.berifymeMessageHandler.postMessage(messageData);
                }
                if (originalRNPostMessage) {
                    originalRNPostMessage.call(window.ReactNativeWebView, data);
                }
            };
            var originalPostMessage = window.postMessage;
            window.postMessage = function(data) {
                var messageData;
                if (typeof data === 'string') {
                    try {
                        messageData = JSON.parse(data);
                    } catch(e) {
                        messageData = { event: 'message', data: data };
                    }
                } else {
                    messageData = data;
                }
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.berifymeMessageHandler) {
                    window.webkit.messageHandlers.berifymeMessageHandler.postMessage(messageData);
                }
                if (originalPostMessage) {
                    originalPostMessage.call(window, data);
                }
            };
        })();
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(self, name: "berifymeMessageHandler")
        webView.configuration.userContentController = userContentController
        
        setupUI()
        startVerification()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func startVerification() {
        Task {
            let permissions = PermissionService.checkAllPermissions()
            if permissions.camera != .authorized {
                await MainActor.run {
                    onError("Camera permission not granted. Please enable in Settings > Privacy & Security > Camera.")
                }
                return
            }
            let photoLibraryAuthorized: Bool
            if #available(iOS 14.0, *) {
                photoLibraryAuthorized = permissions.photoLibrary == .authorized || permissions.photoLibrary == .limited
            } else {
                photoLibraryAuthorized = permissions.photoLibrary == .authorized
            }
            
            if !photoLibraryAuthorized {
                await MainActor.run {
                    onError("Photo library permission not granted. Please enable in Settings > Privacy & Security > Photos.")
                }
                return
            }
            
            do {
                guard let clearAPI = BerifymeSDK.shared.clear else {
                    await MainActor.run {
                        onError("Clear API not initialized")
                    }
                    return
                }
                let path = isOnboarding ? "ReactNativeSDKClearWebViewOnBoarding" : "ReactNativeSDKClearWebViewLogin"
                let webviewURL = "\(environment.webviewDomain)/\(path)?token=\(token)&userId=\(user.id)"
                
                await MainActor.run {
                    if let url = URL(string: webviewURL) {
                        let request = URLRequest(url: url)
                        webView.load(request)
                    } else {
                        onError("Invalid URL: \(webviewURL)")
                    }
                }
            } catch {
                await MainActor.run {
                    onError(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    private func extractSessionIdFromURL(_ urlString: String) {
        if let url = URL(string: urlString),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "sessionId" || item.name == "session_id" {
                    if let sessionId = item.value {
                        self.sessionId = sessionId
                        checkApproval()
                        return
                    }
                }
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = url.absoluteString
        
        if urlString == "about:blank" || urlString.hasPrefix("about:") {
            decisionHandler(.cancel)
            return
        }
        if urlString.contains("callback") || urlString.contains("success") || urlString.contains("approved") || urlString.contains("complete") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if self?.sessionId == nil {
                    self?.extractSessionIdFromURL(urlString)
                }
            }
        }
        decisionHandler(.allow)
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        onError(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        let errorDescription = error.localizedDescription
        if errorDescription.contains("about:blank") || errorDescription.contains("about:") { return }
        if let nsError = error as NSError?, nsError.code == NSURLErrorCancelled { return }
        onError(errorDescription)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let event = messageBody["event"] as? String else { return }
        
        if event == "onSuccess", let sessionId = messageBody["sessionId"] as? String {
            self.sessionId = sessionId
            checkApproval()
        } else if event == "onExit" {
            if sessionId == nil {
                onError("User cancelled verification")
            }
        }
    }
    
    private func checkApproval() {
        guard let sessionId = sessionId else { return }
        
        Task {
            do {
                guard let clearAPI = BerifymeSDK.shared.clear else {
                    await MainActor.run { onError("Clear API not initialized") }
                    return
                }
                
                if isOnboarding {
                    let approveResponse = try await clearAPI.getClearApprove(
                        id: user.id,
                        sessionId: sessionId,
                        token: token
                    )
                    
                    await MainActor.run {
                        if approveResponse.clearId != nil {
                            Task { await self.getUserBySessionId(sessionId: sessionId) }
                        } else {
                            onError(approveResponse.error ?? "Verification failed")
                        }
                    }
                } else {
                    await getUserBySessionId(sessionId: sessionId)
                }
            } catch {
                await MainActor.run { onError(error.localizedDescription) }
            }
        }
    }
    
    private func getUserBySessionId(sessionId: String) async {
        do {
            guard let userAPI = BerifymeSDK.shared.user else {
                await MainActor.run {
                    onError("User API not initialized")
                }
                return
            }
            
            let verificationStatus: VerificationStatus = isOnboarding ? .onboarding : .login
            let response = try await userAPI.getUserBySessionId(
                sessionId: sessionId,
                verificationStatus: verificationStatus,
                token: token
            )
            
            await MainActor.run {
                if response.user != nil {
                    onComplete()
                } else {
                    onError(response.error ?? "Failed to get user info")
                }
            }
        } catch {
            await MainActor.run { onError(error.localizedDescription) }
        }
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "berifymeMessageHandler")
    }
}
