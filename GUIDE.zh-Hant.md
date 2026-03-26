# Berify.me iOS Swift SDK — 整合指南

## 📋 目錄

- [快速開始（約 5 分鐘整合）](#快速開始約-5-分鐘整合)
- [整合流程](#整合流程)
- [SDK 設定與使用（UIKit / SwiftUI）](#sdk-設定與使用uikit--swiftui)
- [設定與流程（環境、網域、Loading、供應商選擇）](#設定與流程)
- [iOS 權限](#ios-權限)
- [除錯與疑難排解](#除錯與疑難排解)

---

## 快速開始（約 5 分鐘整合）

### 🚀 最簡測試設定

#### Step 1：建立新專案（約 1 分鐘）

1. 開啟 Xcode
2. **File** > **New** > **Project**
3. 選擇 **iOS** > **App**
4. 填寫：
   - Product Name：`SDKTest`
   - Interface：**Storyboard**（最簡單）
   - Language：**Swift**
   - Minimum Deployment：**iOS 13.0**
5. 點擊 **Create**

#### Step 2：加入 SDK（約 1 分鐘）

1. 在 Xcode 左側面板點擊專案名稱（上方藍色圖示）
2. 選擇專案（不要選 Target）
3. 點擊 **Package Dependencies** 分頁
4. 點擊 **+**
5. 點擊 **Add Local...**
6. 選擇 SDK 目錄（請使用**相對路徑**或您的本機路徑）：
   - 若 SDK 在您的專案內：瀏覽到專案根目錄下的 SDK 資料夾
   - 若 SDK 在其他位置：選擇內含 `Package.swift` 與 `Sources/BerifymeSDK` 的資料夾

```
<SDK 資料夾路徑>
```

7. 點擊 **Add Package**
8. 選擇 **BerifymeSDK**
9. 點擊 **Add Package**

#### Step 3：設定 SDK（約 1 分鐘）

> SwiftUI 請參考下方「[SDK 設定與使用（UIKit / SwiftUI）](#sdk-設定與使用uikit--swiftui)」的 SwiftUI 範例；UIKit 請參考 UIKit 範例。

#### Step 4：加入測試按鈕（約 1 分鐘）

UIKit（Storyboard）請在 `ViewController.swift` 中加入一個按鈕，並呼叫 `presentModal`（完整範例見下方「SDK 設定與使用」）。

#### Step 5：加入權限說明（Info.plist）

驗證流程會使用相機等裝置，請在專案的 **Info.plist** 中加入以下 key 並填寫說明文字（不可為空）：

- `NSCameraUsageDescription` — 例：用於身分驗證
- `NSPhotoLibraryUsageDescription` — 例：用於上傳身分證明文件

詳細說明與其他選項見 [iOS 權限](#ios-權限)。

#### Step 6：執行測試（約 1 分鐘）

1. 連接實體手機（建議—SDK 會使用相機進行驗證）或選擇模擬器
2. 按 **Cmd + R** 執行
3. 點擊「Start verification」按鈕
4. 測試 SDK 流程

---

## 整合流程

### 📊 完整整合流程

```
┌─────────────────────────────────────────────────────────────┐
│  1. 建立新 iOS 專案                                           │
│  Xcode > File > New > Project > iOS > App                   │
│  - Product Name: SDKTest                                    │
│  - Interface: Storyboard                                    │
│  - Language: Swift                                          │
│  - Minimum Deployment: iOS 13.0+                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. 加入 Swift Package 依賴                                  │
│  Project Settings > Package Dependencies > +                │
│  - 選擇 "Add Local..."                                      │
│  - 瀏覽到 SDK 資料夾（內含 Package.swift）                     │
│  - 選擇 BerifymeSDK 產品                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. 設定 SDK（AppDelegate）                                  │
│  import BerifymeSDK                                         │
│  BerifymeSDK.shared.configure(                              │
│    apiKeyId: "YOUR_KEY",                                    │
│    secretKey: "YOUR_SECRET",                                │
│    environment: .idv                                        │
│  )                                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. 建立測試按鈕（ViewController）                             │
│  - 加入 UIButton                                             │
│  - 設定 action: showSDK()                                    │
│  - 在 showSDK() 中呼叫 presentModal()                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. 加入權限說明（Info.plist）                                 │
│  - NSCameraUsageDescription                                 │
│  - NSPhotoLibraryUsageDescription                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6. 執行測試                                                 │
│  - 使用實體裝置（建議）或模擬器                                 │
│  - 按 Cmd + R 執行                                           │
│  - 點擊按鈕測試 SDK                                           │
└─────────────────────────────────────────────────────────────┘
```

### 🔄 SDK 使用流程（Onboarding / Login）

```
使用者點擊「Start verification」
        ↓
┌─────────────────────────┐
│ 呼叫 presentModal()      │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 顯示 Loading 頁面        │
│ 建立 Session Token       │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 顯示簡訊輸入頁面           │
│ 使用者輸入手機號碼         │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 發送驗證                 │
│ (AuthAPI)               │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 顯示驗證碼輸入            │
│ 使用者輸入驗證碼           │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 驗證驗證碼               │
│ (UserAPI)               │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ KYC 驗證                │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ 驗證完成                 │
│ 回傳 Token               │
│ (onComplete)            │
└─────────────────────────┘
```

---

## SDK 設定與使用（UIKit / SwiftUI）

### UIKit（AppDelegate + ViewController）

#### 1) 設定

```swift
import UIKit
import BerifymeSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        BerifymeSDK.shared.configure(
            apiKeyId: "YOUR_API_KEY_ID",
            secretKey: "YOUR_SECRET_KEY",
            environment: .idv
        )
        return true
    }
}
```

#### 2) 顯示視窗

```swift
import UIKit
import BerifymeSDK

class ViewController: UIViewController {
    @objc func showSDK() {
        BerifymeSDK.shared.presentModal(
            from: self,
            onUpdate: { updateData in
                print("📱 Page: \(updateData.page?.pageName ?? "")")
            },
            onComplete: { token in
                if let token = token {
                    print("✅ Success! Token: \(token)")
                } else {
                    print("❌ Cancelled or failed")
                }
            }
        )
    }
}
```

**Incode 語系（選填）：** 若要固定介面語言，在 `presentModal` 傳入 `locale`。可用值：`"en"`、`"zh-TW"`、`"mix"`。若不傳 `locale`，SDK 會依手機語系偏好自動選擇（一般繁體中文環境為繁中，其餘多為英文）。

### SwiftUI（App + UIViewControllerRepresentable）

> SwiftUI 需透過 `UIViewControllerRepresentable` 包一層才能顯示 UIKit 的 modal。

```swift
import SwiftUI
import BerifymeSDK

@main
struct SDKTestApp: App {
    init() {
        BerifymeSDK.shared.configure(
            apiKeyId: "YOUR_API_KEY_ID",
            secretKey: "YOUR_SECRET_KEY",
            environment: .idv
        )
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var showVerification = false
    @State private var verificationToken: String?

    var body: some View {
        VStack(spacing: 30) {
            Text("Berify.me SDK Test")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button("Start verification") { showVerification = true }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.blue)
                .cornerRadius(10)

            if let token = verificationToken {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✅ Verification success!").font(.headline).foregroundColor(.green)
                    Text("Token: \(token)").font(.caption).foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $showVerification) {
            VerificationWrapper(token: $verificationToken)
        }
    }
}

struct VerificationWrapper: UIViewControllerRepresentable {
    @Binding var token: String?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            BerifymeSDK.shared.presentModal(
                from: viewController,
                onUpdate: { updateData in
                    print("📱 Page: \(updateData.page?.pageName ?? "")")
                },
                onComplete: { receivedToken in
                    token = receivedToken
                    dismiss()
                }
            )
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

### ⚠️ SwiftUI 注意事項

- `Environment` 可能與 `BerifymeSDK.Environment` 衝突：請明確使用 `@SwiftUI.Environment` 或 `BerifymeSDK.Environment`。

---

## 設定與流程

### Loading 頁面（/loading）

- **不要阻擋**導向 `/loading` 的導覽
- **不要強制逾時**；讓頁面自然 redirect 或 postMessage
- **持續監聽** WebView 的 message／導覽

### 供應商選擇邏輯

- **新使用者（Onboarding）**：顯示供應商選擇；順序依 `getOrderByCountry`。
- **既有使用者（Login）**：依 `getUserVenderByPhone` 的 vender 決定流程；僅在無資料時顯示選擇。

---

## iOS 權限

### Info.plist 權限說明

驗證流程若會使用到以下功能，請在 Info.plist 加入對應 key，並填寫說明文字（不可為空，否則可能審核被拒或執行時閃退）：

- `NSCameraUsageDescription` — 驗證流程使用相機時必填
- `NSPhotoLibraryUsageDescription` — 驗證流程使用相簿／上傳檔案時必填
- `NSMicrophoneUsageDescription` — 驗證流程使用麥克風時必填（未使用可省略）
- `NSFaceIDUsageDescription` — 驗證流程使用 Face ID 時必填，且**不可為空字串**
- `NSLocationWhenInUseUsageDescription` — 驗證流程需要定位時必填（未使用可省略）

### Face ID 說明

若出現：

```
The value for NSFaceIDUsageDescription must be a non-empty string.
```

表示 `NSFaceIDUsageDescription` 為空或未設定；請設為非空字串。

### 權限請求時機

- 相機／相簿／麥克風：進入驗證流程時依需要請求
- Face ID：僅檢查是否可用；實際使用時由系統提示
- 定位：依驗證流程需要時請求

---

## 除錯與疑難排解

### 常見建置錯誤

- **iOS API 限制**：若最低為 iOS 13+，請避免使用需 iOS 14+ 的 API
- **Environment 歧義**：請明確使用 `SwiftUI.Environment` 或 `BerifymeSDK.Environment`
- **No such module 'BerifymeSDK'**：執行 Clean Build Folder、Reset Package Caches

### 執行時問題

- **Modal 沒有出現**：確認在主執行緒、SDK 已設定、父層 VC 已有 view
- **WebView 無法載入**：檢查 `NSAppTransportSecurity`

### WebView 卡住

若驗證後流程沒有繼續，請檢查：

- WebView 有收到 `postMessage`（onSuccess）
- sessionId 不為空
- 權限（相機／相簿／Face ID／定位）已授權
- 網址可連線
