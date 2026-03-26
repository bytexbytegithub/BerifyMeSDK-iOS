import Foundation
import LocalAuthentication
import CryptoKit

/// iOS biometrics flow (minimal usable version)
/// - Goal: Align with RN SDK "try to enable biometrics after verification success"
/// - Note: RN signs payload with device key and uploads publicKey/signature
///   Here we use CryptoKit P256 key; privateKey in Keychain, publicKey in UserDefaults.
enum BiometricsService {
    private static let keychainService = "com.berifyme.sdk.biometrics"
    private static let publicKeyDefaultsKeyPrefix = "berifyme_biometrics_publicKey_"
    private static let privateKeyAccountPrefix = "berifyme_biometrics_privateKey_"
    
    static func startBiometricsIfNeeded(phoneNumber: String) {
        Task {
            do {
                // Ask backend if biometrics already exists (non-blocking)
                guard let api = BerifymeSDK.shared.biometrics else { return }
                let status = try await api.checkBiometricsStatus(phoneNumber: phoneNumber, publicKey: nil)
                
                // If already set, do nothing (align RN SDK: status === 'Match' or exists === true)
                if status.isSet {
                    return
                }
                
                // Check device support
                let context = LAContext()
                var err: NSError?
                guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
                    return
                }
                
                // Trigger biometrics prompt once
                let ok = try await evaluateBiometrics(context: context, reason: "Enable Face ID / Touch ID for faster verification next time.")
                guard ok else { return }
                
                // Generate/save key and upload
                _ = try await enableBiometrics(phoneNumber: phoneNumber)
            } catch {
                // Silent failure; do not block main flow
            }
        }
    }

    /// Read stored publicKey (for RN SendSNS biometrics match check)
    static func storedPublicKey(phoneNumber: String) -> String? {
        let key = publicKeyDefaultsKeyPrefix + phoneNumber
        let v = UserDefaults.standard.string(forKey: key)
        return (v?.isEmpty == false) ? v : nil
    }
    
    static func enableBiometrics(phoneNumber: String) async throws -> CreateBiometricsResponse? {
        guard let api = BerifymeSDK.shared.biometrics else { return nil }
        
        let privateKey = P256.Signing.PrivateKey()
        let privateKeyData = privateKey.rawRepresentation
        let publicKeyData = privateKey.publicKey.rawRepresentation
        
        let privateAccount = privateKeyAccountPrefix + phoneNumber
        _ = KeychainStore.saveData(privateKeyData, service: keychainService, account: privateAccount)
        
        let publicKeyBase64 = publicKeyData.base64EncodedString()
        UserDefaults.standard.set(publicKeyBase64, forKey: publicKeyDefaultsKeyPrefix + phoneNumber)
        
        // payload = phoneNumber (align RN payload)
        let payloadData = Data(phoneNumber.utf8)
        let signature = try privateKey.signature(for: payloadData)
        let signatureBase64 = signature.derRepresentation.base64EncodedString()
        
        return try await api.createBiometrics(
            phoneNumber: phoneNumber,
            publicKey: publicKeyBase64,
            signature: signatureBase64
        )
    }
    
    static func disableBiometrics(phoneNumber: String) async {
        let privateAccount = privateKeyAccountPrefix + phoneNumber
        _ = KeychainStore.deleteData(service: keychainService, account: privateAccount)
        UserDefaults.standard.removeObject(forKey: publicKeyDefaultsKeyPrefix + phoneNumber)
        
        do {
            if let api = BerifymeSDK.shared.biometrics {
                _ = try await api.deleteBiometrics(phoneNumber: phoneNumber)
            }
        } catch { }
    }
    
    // MARK: - Helpers
    
    private static func evaluateBiometrics(context: LAContext, reason: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    // User cancel is not an error (return false)
                    if (error as NSError).code == LAError.userCancel.rawValue ||
                        (error as NSError).code == LAError.systemCancel.rawValue {
                        cont.resume(returning: false)
                        return
                    }
                    cont.resume(throwing: error)
                    return
                }
                cont.resume(returning: success)
            }
        }
    }
}

