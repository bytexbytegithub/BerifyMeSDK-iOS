# Berify.me iOS Swift SDK

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)

Berify.me iOS Swift SDK is a native identity verification (KYC/IDV) solution for iOS apps. It provides a simple API for integrating verification into your app.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Full integration guide (GUIDE.md)](#full-integration-guide-guidemd)
- [API Reference](#api-reference)

## ✨ Features

- 🔐 **KYC verification**: Identity verification flow
- 📱 **Phone verification**: SMS code authentication
- 🎨 **Native UI**: Full native iOS UI components
- 🔄 **Dual flows**: Onboarding and Login
- 🔒 **Biometrics**: Face ID and Touch ID

## 📦 Requirements

- **iOS**: 13.0+
- **Swift**: 5.9+
- **Xcode**: 14.0+

## 📥 Installation

Add this to your `Podfile`:

```ruby
platform :ios, '13.0'

target 'YourApp' do
  use_frameworks! :linkage => :static
  pod 'BerifymeSDK', '1.2.0'
end
```

Then run:

```bash
pod install
```

After installation, open the generated `.xcworkspace` in Xcode.

## 🚀 Quick Start

### 1. Import SDK

```swift
import BerifymeSDK
```

### 2. Configure SDK

In `AppDelegate` or `SceneDelegate`:

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

### 3. Present verification modal

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
                    // Use token for subsequent operations
                }
            }
        )
    }
}
```

## 📚 Full integration guide (GUIDE.md)

iOS SDK documentation is consolidated in:

- `GUIDE.md`

## 📖 API Reference

### BerifymeSDK

Main SDK class (singleton).

#### Methods

##### `configure(apiKeyId:secretKey:environment:)`

Configure the SDK.

```swift
BerifymeSDK.shared.configure(
    apiKeyId: "YOUR_API_KEY_ID",
    secretKey: "YOUR_SECRET_KEY",
    environment: .idv
)
```

##### `presentModal(from:verifiedExternalPhoneNumber:onUpdate:onComplete:)`

Present the verification modal.

**Parameters:**
- `from`: Parent view controller
- `verifiedExternalPhoneNumber`: Pre-verified external phone number (optional)
- `onUpdate`: Status update callback
- `onComplete`: Completion callback with verification token