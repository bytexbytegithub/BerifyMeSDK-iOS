import AVFoundation
import WebKit

/// iOS 15+：`WKWebView` 內 `getUserMedia` 須透過 `WKUIDelegate.requestMediaCapturePermissionFor` 回覆；與「設定 → Safari → 相機」無關，而是 **嵌入 App** 的相機／麥克風授權狀態。
enum WKMediaCapturePermission {
    @available(iOS 15.0, *)
    static func decision(for type: WKMediaCaptureType) -> WKPermissionDecision {
        let video = AVCaptureDevice.authorizationStatus(for: .video)
        let audio = AVCaptureDevice.authorizationStatus(for: .audio)
        switch type {
        case .camera:
            return decision(for: video)
        case .microphone:
            return decision(for: audio)
        case .cameraAndMicrophone:
            if video == .authorized, audio == .authorized { return .grant }
            if video == .notDetermined || audio == .notDetermined { return .prompt }
            return .deny
        @unknown default:
            return .prompt
        }
    }

    @available(iOS 15.0, *)
    private static func decision(for status: AVAuthorizationStatus) -> WKPermissionDecision {
        switch status {
        case .authorized:
            return .grant
        case .notDetermined:
            return .prompt
        case .denied, .restricted:
            return .deny
        @unknown default:
            return .prompt
        }
    }
}
