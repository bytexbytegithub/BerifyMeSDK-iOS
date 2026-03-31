# Berify.me iOS Swift SDK

[![Swift 版本](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)

Berify.me iOS Swift SDK 是專為 iOS 應用設計的原生身分驗證（KYC/IDV）方案，提供簡潔的 API 以整合驗證流程。

## 📋 目錄

- [功能特色](#功能特色)
- [系統需求](#系統需求)
- [安裝方式](#安裝方式)
- [快速開始](#快速開始)
- [完整整合指南 (GUIDE.md)](#完整整合指南-guidemd)
- [API 參考](#api-參考)

## ✨ 功能特色

- 🔐 **KYC 驗證**：身分驗證流程
- 📱 **手機驗證**：簡訊驗證碼驗證
- 🎨 **原生介面**：完整原生 iOS UI 元件
- 🔄 **雙流程**：Onboarding 與 Login
- 🔒 **生物辨識**：Face ID、Touch ID

## 📦 系統需求

- **iOS**：13.0 以上
- **Swift**：5.9 以上
- **Xcode**：14.0 以上

## 📥 安裝方式

在 `Podfile` 中加入：

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks! :linkage => :static
  pod 'BerifymeSDK', '1.2.0'
end
```

接著執行：

```bash
pod install
```

安裝完成後，請使用 Xcode 開啟產生的 `.xcworkspace`。

## 🚀 快速開始

### 1. 匯入 SDK

```swift
import BerifymeSDK
```

### 2. 設定 SDK

在 `AppDelegate` 或 `SceneDelegate` 中：

```swift
import BerifymeSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    BerifymeSDK.shared.configure(
        apiKeyId: "YOUR_API_KEY_ID",
        secretKey: "YOUR_SECRET_KEY",
        environment: .idv
    )
    return true
}
```

### 3. 顯示驗證視窗

```swift
import BerifymeSDK

class ViewController: UIViewController {
    @IBAction func showVerification(_ sender: Any) {
        BerifymeSDK.shared.presentModal(
            from: self,
            verifiedExternalPhoneNumber: nil,
            onUpdate: { updateData in
                print("Page update: \(updateData.page?.pageName ?? "unknown")")
                if let message = updateData.message {
                    print("Message: \(message)")
                }
            },
            onComplete: { token in
                if let token = token {
                    print("Verification complete, Token: \(token)")
                    // 使用 token 進行後續操作
                }
            }
        )
    }
}
```

## 📚 完整整合指南 (GUIDE.md)

iOS SDK 的完整說明集中於：

- `GUIDE.md`

## 📖 API 參考

### BerifymeSDK

SDK 主類別（單例）。

#### 方法

##### `configure(apiKeyId:secretKey:environment:)`

設定 SDK。

```swift
BerifymeSDK.shared.configure(
    apiKeyId: "YOUR_API_KEY_ID",
    secretKey: "YOUR_SECRET_KEY",
    environment: .idv
)
```

##### `presentModal(from:verifiedExternalPhoneNumber:onUpdate:onComplete:)`

顯示驗證視窗。

**參數：**
- `from`：父層 View Controller
- `verifiedExternalPhoneNumber`：已驗證的外部手機號碼（選填）
- `onUpdate`：狀態更新回呼
- `onComplete`：完成回呼，回傳驗證 token