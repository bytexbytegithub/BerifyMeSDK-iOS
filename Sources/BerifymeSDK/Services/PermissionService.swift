import Foundation
import AVFoundation
import Photos
import LocalAuthentication
@preconcurrency import CoreLocation

/// Location manager delegate (for requesting location permission)
private final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    var continuation: CheckedContinuation<Bool, Never>?
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Only handle when status changed and not undetermined
        guard status != .notDetermined, let continuation = continuation else {
            return
        }
        
        self.continuation = nil
        let authorized = status == .authorizedWhenInUse || status == .authorizedAlways
        continuation.resume(returning: authorized)
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // iOS 14+ use instance property
        let status = manager.authorizationStatus
        
        guard status != .notDetermined, let continuation = continuation else {
            return
        }
        
        self.continuation = nil
        let authorized = status == .authorizedWhenInUse || status == .authorizedAlways
        continuation.resume(returning: authorized)
    }
}

/// Permission service - check and request various permissions
public class PermissionService {
    // Keep strong reference to location manager
    private static var locationManager: CLLocationManager?
    private static var locationDelegate: LocationManagerDelegate?
    
    /// Check camera permission status
    public static func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Request camera permission
    public static func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Check microphone permission status
    public static func checkMicrophonePermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    /// Request microphone permission
    public static func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Check photo library permission status
    public static func checkPhotoLibraryPermission() -> PHAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            // iOS 13 use legacy API
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    
    /// Request photo library permission
    public static func requestPhotoLibraryPermission() async -> Bool {
        if #available(iOS 14.0, *) {
            // iOS 14+ use new API
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            switch status {
            case .authorized, .limited:
                return true
            case .notDetermined:
                let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                return newStatus == .authorized || newStatus == .limited
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }
        } else {
            // iOS 13 use legacy API (needs async conversion)
            let status = PHPhotoLibrary.authorizationStatus()
            
            switch status {
            case .authorized, .limited:
                return true
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization { newStatus in
                        continuation.resume(returning: newStatus == .authorized)
                    }
                }
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }
        }
    }
    
    /// Check Face ID/Touch ID availability
    public static func checkBiometricAvailability() -> (available: Bool, type: String) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .faceID:
                    return (true, "Face ID")
                case .opticID:
                    return (true, "Optic ID")
                case .touchID:
                    return (true, "Touch ID")
                case .none:
                    return (false, "None")
                @unknown default:
                    return (false, "Unknown")
                }
            } else {
                return (true, "Touch ID")
            }
        } else {
            return (false, "Unavailable")
        }
    }
    
    /// Request Face ID/Touch ID permission (warm-up permission request)
    public static func requestFaceIDPermission() async -> (success: Bool, type: String, error: String?) {
        let biometric = checkBiometricAvailability()
        
        if !biometric.available {
            return (false, biometric.type, "Device does not support \(biometric.type) or it is not enabled")
        }
        
        // Perform one biometric evaluation to "warm up" permission request
        // This triggers the system to show Face ID/Touch ID dialog if not yet granted
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                // Evaluate policy to trigger permission request
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Use \(biometric.type) for authentication"
                )
                return (success, biometric.type, nil)
            } catch {
                // User cancel or deny is not an error, just user choice
                return (false, biometric.type, "User cancelled or denied \(biometric.type)")
            }
        } else {
            return (false, biometric.type, "Cannot evaluate biometric policy")
        }
    }
    
    /// Check Face ID/Touch ID availability (without requesting)
    public static func checkFaceIDPermission() -> (available: Bool, type: String, error: String?) {
        let biometric = checkBiometricAvailability()
        
        if !biometric.available {
            return (false, biometric.type, "Device does not support \(biometric.type) or it is not enabled")
        }
        
        return (true, biometric.type, nil)
    }
    
    /// Check location permission status
    public static func checkLocationPermission() -> CLAuthorizationStatus {
        // iOS 13 uses static method; iOS 14+ also supports it (backward compatible)
        // Use static method for compatibility
        return CLLocationManager.authorizationStatus()
    }
    
    /// Request location permission
    public static func requestLocationPermission() async -> Bool {
        // Use static method for iOS 13 compatibility
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined:
            // Create CLLocationManager instance to request permission
            return await withCheckedContinuation { continuation in
                let manager = CLLocationManager()
                let delegate = LocationManagerDelegate()
                
                // Keep reference to avoid deallocation
                locationManager = manager
                locationDelegate = delegate
                
                // Set delegate
                manager.delegate = delegate
                
                // Set continuation
                delegate.continuation = continuation
                
                // Request permission
                manager.requestWhenInUseAuthorization()
                
                // If authorization status returned immediately (may happen in some cases)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [delegate] in
                    let currentStatus = CLLocationManager.authorizationStatus()
                    if currentStatus != .notDetermined, let continuation = delegate.continuation {
                        delegate.continuation = nil
                        let authorized = currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
                        continuation.resume(returning: authorized)
                    }
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Request all permissions required for Clear verification
    public static func requestAllPermissions() async -> (camera: Bool, microphone: Bool, photoLibrary: Bool, faceID: (available: Bool, type: String, requested: Bool), location: (authorized: Bool, status: CLAuthorizationStatus), error: String?) {
        var results = (camera: false, microphone: false, photoLibrary: false, faceID: (available: false, type: "None", requested: false), location: (authorized: false, status: CLAuthorizationStatus.notDetermined), error: nil as String?)
        
        // Request camera permission
        results.camera = await requestCameraPermission()
        if !results.camera {
            results.error = "Camera permission denied. Please enable in Settings."
        }
        
        // Request microphone permission (optional but recommended)
        results.microphone = await requestMicrophonePermission()
        
        // Request photo library permission
        results.photoLibrary = await requestPhotoLibraryPermission()
        if !results.photoLibrary {
            if results.error == nil {
                results.error = "Photo library permission denied. Please enable in Settings."
            } else {
                results.error = "\(results.error ?? ""), photo library permission denied"
            }
        }
        
        let faceIDCheck = checkFaceIDPermission()
        if faceIDCheck.available {
            let faceIDRequest = await requestFaceIDPermission()
            results.faceID = (faceIDRequest.success, faceIDRequest.type, true)
        } else {
            results.faceID = (false, faceIDCheck.type, false)
        }
        
        let locationAuthorized = await requestLocationPermission()
        let locationStatus = checkLocationPermission()
        results.location = (locationAuthorized, locationStatus)
        
        return results
    }
    
    /// Check all permission status (without requesting)
    public static func checkAllPermissions() -> (camera: AVAuthorizationStatus, microphone: AVAuthorizationStatus, photoLibrary: PHAuthorizationStatus, faceID: (available: Bool, type: String), location: CLAuthorizationStatus) {
        return (
            camera: checkCameraPermission(),
            microphone: checkMicrophonePermission(),
            photoLibrary: checkPhotoLibraryPermission(),
            faceID: checkBiometricAvailability(),
            location: checkLocationPermission()
        )
    }
}
