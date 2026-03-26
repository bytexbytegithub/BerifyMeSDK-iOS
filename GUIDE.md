# Berify.me iOS Swift SDK — Integration guide

## 📋 Table of Contents

- [Quick start (5-minute integration)](#quick-start-5-minute-integration)
- [Integration flow](#integration-flow)
- [SDK configuration and usage (UIKit / SwiftUI)](#sdk-configuration-and-usage-uikit--swiftui)
- [Configuration and flow (environment, domains, Loading, provider selection)](#configuration-and-flow)
- [iOS permissions](#ios-permissions)
- [Troubleshooting and debugging](#troubleshooting-and-debugging)

---

## Quick start (5-minute integration)

### 🚀 Minimal test setup

#### Step 1: Create new project (1 min)

1. Open Xcode
2. **File** > **New** > **Project**
3. Choose **iOS** > **App**
4. Fill in:
   - Product Name: `SDKTest`
   - Interface: **Storyboard** (simplest)
   - Language: **Swift**
   - Minimum Deployment: **iOS 13.0**
5. Click **Create**

#### Step 2: Add SDK (1 min)

1. In Xcode left panel, click project name (top blue icon)
2. Select project (not Target)
3. Click **Package Dependencies** tab
4. Click **+**
5. Click **Add Local...**
6. Select the SDK directory (use a **relative path** or your local path):
   - If the SDK is in your project: browse to the SDK folder under your project root
   - If the SDK is elsewhere: select the folder that contains `Package.swift` and `Sources/BerifymeSDK`

```
<path-to-sdk-folder>
```

7. Click **Add Package**
8. Select **BerifymeSDK**
9. Click **Add Package**

#### Step 3: Configure SDK (1 min)

> For SwiftUI see “[SDK configuration and usage (UIKit / SwiftUI)](#sdk-configuration-and-usage-uikit--swiftui)” SwiftUI example; for UIKit see UIKit example.

#### Step 4: Add test button (1 min)

For UIKit (Storyboard), add a button in `ViewController.swift` that calls `presentModal` (full example below in “SDK configuration and usage”).

#### Step 5: Add permission descriptions (Info.plist)

The verification flow uses the camera and other device features. Add these keys to your app's **Info.plist** with non-empty description strings:

- `NSCameraUsageDescription` — e.g. "Used for identity verification"
- `NSPhotoLibraryUsageDescription` — e.g. "Used to upload identity documents"

See [iOS permissions](#ios-permissions) for the full list and details.

#### Step 6: Run test (1 min)

1. Connect a physical device (recommended—SDK uses camera for verification) or select simulator
2. Press **Cmd + R** to run
3. Tap “Start verification” button
4. Test SDK flow

---

## Integration flow

### 📊 Full integration flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Create new iOS project                                  │
│  Xcode > File > New > Project > iOS > App                   │
│  - Product Name: SDKTest                                    │
│  - Interface: Storyboard                                    │
│  - Language: Swift                                          │
│  - Minimum Deployment: iOS 13.0+                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Add Swift Package dependency                            │
│  Project Settings > Package Dependencies > +                │
│  - Choose "Add Local..."                                    │
│  - Browse to: SDK folder (contains Package.swift)           │
│  - Select BerifymeSDK product                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Configure SDK (AppDelegate)                             │
│  import BerifymeSDK                                         │
│  BerifymeSDK.shared.configure(                              │
│    apiKeyId: "YOUR_KEY",                                    │
│    secretKey: "YOUR_SECRET",                                │
│    environment: .idv                                        │
│  )                                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. Create test button (ViewController)                     │
│  - Add UIButton                                             │
│  - Set action: showSDK()                                    │
│  - Call presentModal() in showSDK()                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. Add permission descriptions (Info.plist)                │
│  - NSCameraUsageDescription                                 │
│  - NSPhotoLibraryUsageDescription                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6. Run test                                                │
│  - Use physical device (recommended) or simulator           │
│  - Press Cmd + R to run                                     │
│  - Tap button to test SDK                                   │
└─────────────────────────────────────────────────────────────┘
```

### 🔄 SDK usage flow (Onboarding / Login)

```
User taps "Start verification"
        ↓
┌─────────────────────────┐
│ presentModal() called   │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Show Loading page       │
│ Create Session Token    │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Show SMS input page     │
│ User enters phone       │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Send verification       │
│ (AuthAPI)               │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Show code input         │
│ User enters code        │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Verify code             │
│ (UserAPI)               │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ KYC verification        │
└─────────────────────────┘
        ↓
┌─────────────────────────┐
│ Verification done       │
│ Return Token            │
│ (onComplete)            │
└─────────────────────────┘
```

---

## SDK configuration and usage (UIKit / SwiftUI)

### UIKit (AppDelegate + ViewController)

#### 1) Configure

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

#### 2) Present modal

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

**Incode language (optional):** Pass `locale` in `presentModal` when you want a fixed UI language. Allowed values: `"en"`, `"zh-TW"`, `"mix"`. If you omit `locale`, the SDK chooses a default from the device’s preferred languages (Traditional Chinese environments typically get Chinese; others default to English).

### SwiftUI (App + UIViewControllerRepresentable)

> SwiftUI needs a `UIViewControllerRepresentable` wrapper to present the UIKit modal.

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

### ⚠️ SwiftUI gotchas

- `Environment` can conflict with `BerifymeSDK.Environment`: use `@SwiftUI.Environment` or `BerifymeSDK.Environment` explicitly.

---

## Configuration and flow

### Loading page (/loading)

- **Do not block** navigation to `/loading`
- **Do not force timeout**; let the page redirect or postMessage naturally
- **Keep listening** for WebView message / navigation

### Provider selection logic

- **New user (Onboarding)**: Show provider selection; order from `getOrderByCountry`.
- **Existing user (Login)**: Flow from `getUserVenderByPhone` vender; show selection only if no data.

---

## iOS permissions

### Info.plist permission keys

If your verification flow uses any of the following, add the corresponding key to Info.plist with a non-empty description (required by Apple; empty may cause rejection or runtime crash):

- `NSCameraUsageDescription` — required when the flow uses the camera
- `NSPhotoLibraryUsageDescription` — required when the flow uses photo library / uploads
- `NSMicrophoneUsageDescription` — required when the flow uses microphone (omit if not used)
- `NSFaceIDUsageDescription` — required when the flow uses Face ID; **must be non-empty**
- `NSLocationWhenInUseUsageDescription` — required when the flow uses location (omit if not used)

### Face ID note

If you see:

```
The value for NSFaceIDUsageDescription must be a non-empty string.
```

then `NSFaceIDUsageDescription` is empty or missing; set a non-empty string.

### Permission request flow

- Camera / photo library / microphone: requested when entering the verification flow as needed
- Face ID: only check availability; system prompts when used
- Location: requested when needed by the verification flow

---

## Troubleshooting and debugging

### Common build errors

- **iOS API limits**: For iOS 13+, avoid APIs that require iOS 14+
- **Environment ambiguity**: Use `SwiftUI.Environment` / `BerifymeSDK.Environment` explicitly
- **No such module 'BerifymeSDK'**: Clean Build Folder, Reset Package Caches

### Runtime issues

- **Modal not showing**: Ensure main thread, SDK configured, parent VC has view
- **WebView not loading**: Check `NSAppTransportSecurity`

### Clear WebView stuck

If flow does not advance after verification, check:

- WebView receives `postMessage` (onSuccess)
- sessionId is not empty
- Permissions (camera/photo/Face ID/location) are granted
- URL is reachable
