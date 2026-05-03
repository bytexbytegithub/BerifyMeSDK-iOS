import UIKit
import WebKit

/// Shared process pool for WebViews to reduce cold start and speed up loading
private let sharedWebViewProcessPool = WKProcessPool()

/// Default error message when Incode does not return a message.
private let defaultIncodeErrorMessage = "Something went wrong, but we're working on it. Please try again later or contact support for assistance."

/// 與 React Native SDK / Web Frontend 一致：掛載後暫禁 Web 端語言按鈕（毫秒）
private let langSwitchCooldownMs = 2000

/// 語系切換後等待相機釋放再載入新頁（與 RNSDK 一致）
private let cameraReleaseDelaySeconds: TimeInterval = 0.5

/// Incode 流程以 `WKWebView` 載入 Web Frontend：`/ReactNativeSDKIncodeWebViewLogin`（`renderAuthFace` 人臉登入）、`/ReactNativeSDKIncodeWebViewOnBoarding`（Welcome onboarding）。
/// 與 RN SDK 相同之 `postMessage` 橋接、`locale`／`langCooldown` query、語系切換後延遲重載（釋放相機）。
class IncodeWebView: UIView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let webView: WKWebView
    private let loadingIndicator: UIActivityIndicatorView
    private let loadingLabel: UILabel

    private let user: User
    private let token: String
    private let environment: Environment
    private let isOnboarding: Bool
    /// 臉齡流程：與 onboarding 相同載入 `userId`／`token`，路徑為 `ReactNativeSDKFaceAgeEstimationWebView`
    private let faceAgeEstimation: Bool
    private let onComplete: (User?) -> Void
    private let onError: (String) -> Void

    /// 目前載入 URL 使用的語系（en | zh-TW | mix）；可由 Web 端 `changeLocale` 更新並重建 WebView）
    private var currentLocale: String

    init(
        user: User,
        token: String,
        environment: Environment,
        isOnboarding: Bool,
        faceAgeEstimation: Bool = false,
        locale: String? = nil,
        onComplete: @escaping (User?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.user = user
        self.token = token
        self.environment = environment
        self.isOnboarding = isOnboarding
        self.faceAgeEstimation = faceAgeEstimation
        self.onComplete = onComplete
        self.onError = onError
        self.currentLocale = Self.normalizeLocale(locale)

        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingLabel = UILabel()

        let config = WKWebViewConfiguration()
        config.processPool = sharedWebViewProcessPool
        config.preferences.javaScriptEnabled = true
        if #available(iOS 15.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let userContentController = WKUserContentController()
        let script = """
        (function() {
            if (!window.ReactNativeWebView) { window.ReactNativeWebView = {}; }
            function toMessageData(data) {
                if (typeof data === 'string') {
                    try { return JSON.parse(data); } catch(e) { return { event: 'message', data: data }; }
                }
                return data;
            }
            function sendToNative(messageData) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.berifymeSDK) {
                    window.webkit.messageHandlers.berifymeSDK.postMessage(messageData);
                }
            }
            var originalRNPostMessage = window.ReactNativeWebView.postMessage;
            window.ReactNativeWebView.postMessage = function(data) {
                sendToNative(toMessageData(data));
                if (originalRNPostMessage) { originalRNPostMessage.call(window.ReactNativeWebView, data); }
            };
            var originalPostMessage = window.postMessage;
            window.postMessage = function(data) {
                sendToNative(toMessageData(data));
                if (originalPostMessage) { originalPostMessage.call(window, data); }
            };
        })();
        """

        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: config)

        super.init(frame: .zero)
        webView.configuration.userContentController.add(self, name: "berifymeSDK")

        setupUI()
        loadIncodePage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 未指定 `locale` 時依裝置慣用語系：繁中（zh-TW / zh-Hant / zh-HK）→ `zh-TW`，其餘 → `en`（與 Web / Incode URL 邏輯一致）
    private static func defaultLocaleFromDevice() -> String {
        guard let lang = Locale.preferredLanguages.first?.lowercased() else { return "en" }
        if lang.hasPrefix("zh-tw") || lang.hasPrefix("zh-hant") || lang.hasPrefix("zh-hk") {
            return "zh-TW"
        }
        return "en"
    }

    /// `raw` 為 nil 或空白時使用裝置預設；`en` | `zh-TW` | `mix` 為合法值，其餘顯式字串回退為 `en`
    private static func normalizeLocale(_ raw: String?) -> String {
        let allowed: Set<String> = ["en", "zh-TW", "mix"]
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            return defaultLocaleFromDevice()
        }
        return allowed.contains(trimmed) ? trimmed : "en"
    }

    private func setupUI() {
        backgroundColor = .white

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        addSubview(loadingIndicator)

        loadingLabel.text = "Loading…"
        loadingLabel.font = .systemFont(ofSize: 15, weight: .medium)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 12),
            loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func loadIncodePage() {
        if !isOnboarding && !faceAgeEstimation {
            guard let incodeId = user.incodeId, !incodeId.isEmpty else {
                onError("User has no Incode ID")
                return
            }
        }
        guard let url = buildIncodeURL() else {
            onError("Invalid WebView URL")
            return
        }
        webView.load(URLRequest(url: url))
    }

    private func buildIncodeURL() -> URL? {
        let path: String
        if faceAgeEstimation {
            path = "/ReactNativeSDKFaceAgeEstimationWebView"
        } else if isOnboarding {
            path = "/ReactNativeSDKIncodeWebViewOnBoarding"
        } else {
            path = "/ReactNativeSDKIncodeWebViewLogin"
        }

        guard var components = URLComponents(string: environment.webviewDomain + path) else {
            return nil
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "locale", value: currentLocale),
            URLQueryItem(name: "langCooldown", value: String(langSwitchCooldownMs))
        ]

        if isOnboarding || faceAgeEstimation {
            items.append(URLQueryItem(name: "userId", value: user.id))
            items.append(URLQueryItem(name: "token", value: token))
        } else {
            guard let incodeId = user.incodeId, !incodeId.isEmpty else {
                return nil
            }
            items.append(URLQueryItem(name: "token", value: token))
            items.append(URLQueryItem(name: "incodeId", value: incodeId))
        }

        components.queryItems = items
        return components.url
    }

    /// Web LangSelector → postMessage changeLocale：停止相機、延遲後以新 locale 重新載入（對齊 RNSDK）
    private func rebuildForLocaleChange(to newLocale: String) {
        let normalized = Self.normalizeLocale(newLocale)
        currentLocale = normalized

        showLoadingForRebuild()
        let js = """
        (function() {
            try {
                document.querySelectorAll('video').forEach(function(v) {
                    try {
                        if (v.srcObject && v.srcObject.getTracks) {
                            v.srcObject.getTracks().forEach(function(t) { t.stop(); });
                            v.srcObject = null;
                        }
                    } catch(e) {}
                });
            } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + cameraReleaseDelaySeconds) { [weak self] in
            guard let self = self else { return }
            guard let url = self.buildIncodeURL() else {
                self.onError("Invalid WebView URL")
                return
            }
            self.webView.load(URLRequest(url: url))
        }
    }

    private func showLoadingForRebuild() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        loadingLabel.isHidden = false
    }

    // MARK: - WKNavigationDelegate

    private func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        loadingLabel.isHidden = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoading()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoading()
        onError(error.localizedDescription)
    }

    // MARK: - WKUIDelegate（iOS 15+）

    /// 內嵌 `WKWebView` 的 `getUserMedia` **不**吃「設定 → Safari → 相機」；須由 **本 App** 的隱私權與此 callback 授權。未實作時網頁常收不到相機且 Incode 仍顯示 Safari 教學。
    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(WKMediaCapturePermission.decision(for: type))
    }

    /// 支援 body 為 Dictionary 或 JSON 字串（與 Web postMessage(JSON.stringify(...)) 對齊）
    private static func parseMessageBody(_ body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] {
            return dict
        }
        if let s = body as? String,
           let data = s.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        return nil
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = Self.parseMessageBody(message.body),
              let event = messageBody["event"] as? String else {
            return
        }

        switch event {
        case "changeLocale":
            if let newLocale = messageBody["locale"] as? String {
                rebuildForLocaleChange(to: newLocale)
            }
        case "onSuccess":
            var updatedUser: User?
            if let userData = messageBody["user"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: userData),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                updatedUser = user
            }
            onComplete(updatedUser)
        case "onGoBack":
            onError("User cancelled verification")
        case "onExit":
            let incodeMessage = (messageBody["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let errorMessage = incodeMessage.flatMap { $0.isEmpty ? nil : $0 } ?? defaultIncodeErrorMessage
            onError(errorMessage)
        default:
            break
        }
    }
}
