import Foundation

/// deviceId aligned with RN AsyncStorage (persistent UUID)
enum DeviceIdStore {
    private static let key = "berifyme_device_id"
    
    /// Get existing deviceId, or create and save if not present
    static func getOrCreate() -> String {
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    /// Get existing deviceId (do not create)
    static func get() -> String? {
        let v = UserDefaults.standard.string(forKey: key)
        return (v?.isEmpty == false) ? v : nil
    }
}

