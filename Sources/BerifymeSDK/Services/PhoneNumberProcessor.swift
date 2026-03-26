import Foundation

/// Phone number processor (aligned with WebSDK `phoneNumberProcesser.ts` + optional default-country TW national `09…` handling for single-field iOS input).
public enum PhoneNumberProcessor {
    /// Country code prefix rules (Taiwan 886 handled in `normalizeTaiwanDigitsAfterCountryCode`; no `^8860+` here).
    private static let countryPatterns: [(regex: String, replacement: String)] = [
        ("^810+", "81"),
        ("^820+", "82"),
        ("^440+", "44"),
        ("^610+", "61"),
        ("^490+", "49"),
        ("^270+", "27"),
        ("^390+", "39"),
    ]

    /// When default country is TW and user types national `09…` without `886` prefix, normalize to E.164 digits.
    private static func normalizeTaiwanNationalWithoutCountryPrefix(_ digits: String, countryIso2: String?) -> String {
        guard let iso = countryIso2?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), iso == "tw" else {
            return digits
        }
        guard !digits.hasPrefix("886") else { return digits }
        if digits.hasPrefix("09") {
            return "8869" + String(digits.dropFirst(2))
        }
        return digits
    }

    /// Taiwan +886: keep lone trailing `0` after 886; `09…` → `8869…`; else collapse `8860+` → `886`.
    private static func normalizeTaiwanDigitsAfterCountryCode(_ digits: String) -> String {
        guard digits.hasPrefix("886") else { return digits }
        let national = String(digits.dropFirst(3))
        if national == "0" { return digits }
        if national.hasPrefix("09") {
            return "8869" + national.dropFirst(2)
        }
        if let regex = try? NSRegularExpression(pattern: "^8860+") {
            let range = NSRange(digits.startIndex..<digits.endIndex, in: digits)
            return regex.stringByReplacingMatches(in: digits, range: range, withTemplate: "886")
        }
        return digits
    }

    private static func applyCountryPatterns(_ input: String) -> String {
        var processed = input
        for (pattern, replacement) in countryPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            if regex.firstMatch(in: processed, range: range) != nil {
                processed = regex.stringByReplacingMatches(in: processed, range: range, withTemplate: replacement)
            }
        }
        return processed
    }

    /// Process and normalize phone number (digits only, no leading `+`).
    /// - Parameters:
    ///   - phoneNumber: Raw input.
    ///   - countryIso2: Optional ISO 3166-1 alpha-2 (e.g. `"tw"`, `"us"`). Used for TW national `09…` when there is no `886` prefix.
    public static func process(_ phoneNumber: String, countryIso2: String? = nil) -> String {
        var processed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if processed.hasPrefix("+") {
            processed = String(processed.dropFirst())
        }
        processed = processed.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        processed = normalizeTaiwanNationalWithoutCountryPrefix(processed, countryIso2: countryIso2)
        processed = normalizeTaiwanDigitsAfterCountryCode(processed)
        processed = applyCountryPatterns(processed)
        return processed
    }

    /// Validate phone number format (allows `+` and digits in input; length 8…15 digit characters).
    public static func isValid(_ phoneNumber: String) -> Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleaned.count >= 8 && cleaned.count <= 15
    }
}
