import Foundation

/// One selectable country for phone entry (ISO2 + ITU calling code).
struct PhoneCountryOption: Equatable, Hashable {
    let iso2: String
    let callingCode: String

    var localizedRegionName: String {
        if let name = Locale.current.localizedString(forRegionCode: iso2) {
            return name
        }
        return CountryCodeHelper.getCountryNameByCode(iso2)
    }

    func displayTitle(showFlag: Bool) -> String {
        let flag = showFlag ? "\(Self.flagEmoji(for: iso2)) " : ""
        return "\(flag)\(localizedRegionName) (+\(callingCode))"
    }

    static func flagEmoji(for iso2: String) -> String {
        let upper = iso2.uppercased()
        guard upper.count == 2 else { return "" }
        let chars = Array(upper)
        guard let s0 = chars[0].asciiValue, let s1 = chars[1].asciiValue,
              (65...90).contains(s0), (65...90).contains(s1) else { return "" }
        let base: UInt32 = 127397
        guard let u0 = UnicodeScalar(base + UInt32(s0)),
              let u1 = UnicodeScalar(base + UInt32(s1)) else { return "" }
        return String(Character(u0)) + String(Character(u1))
    }
}

enum PhoneCountryCatalog {
    private static var cachedSortedOptions: [PhoneCountryOption]?

    static func allOptionsSorted() -> [PhoneCountryOption] {
        if let cached = cachedSortedOptions { return cached }
        let map = PhoneCountryDialCodes.isoToDial
        let opts = map.map { PhoneCountryOption(iso2: $0.key, callingCode: $0.value) }
            .sorted { $0.localizedRegionName.localizedCaseInsensitiveCompare($1.localizedRegionName) == .orderedAscending }
        cachedSortedOptions = opts
        return opts
    }

    static func option(forIso2 iso2: String) -> PhoneCountryOption? {
        let u = iso2.uppercased()
        guard let dial = PhoneCountryDialCodes.isoToDial[u] else { return nil }
        return PhoneCountryOption(iso2: u, callingCode: dial)
    }

    private static let uniqueCallingCodesLongestFirst: [String] = {
        let codes = Set(PhoneCountryDialCodes.isoToDial.values)
        return codes.sorted { $0.count > $1.count }
    }()

    private static func countries(withCallingCode code: String) -> [PhoneCountryOption] {
        PhoneCountryDialCodes.isoToDial.compactMap { k, v in
            v == code ? PhoneCountryOption(iso2: k, callingCode: v) : nil
        }
    }

    /// Split full international digits (no `+`) using longest calling-code match; `preferredIso2` disambiguates shared codes (e.g. +1, +7).
    static func parse(fullInternationalDigits digits: String, preferredIso2: String) -> (country: PhoneCountryOption, nationalDigits: String)? {
        let d = digits.filter { $0.isNumber }
        guard !d.isEmpty else { return nil }
        let pref = preferredIso2.uppercased()
        for code in uniqueCallingCodesLongestFirst {
            guard d.hasPrefix(code) else { continue }
            let national = String(d.dropFirst(code.count))
            let cands = countries(withCallingCode: code)
            guard !cands.isEmpty else { continue }
            if cands.count == 1 {
                return (cands[0], national)
            }
            if let hit = cands.first(where: { $0.iso2 == pref }) {
                return (hit, national)
            }
            if code == "1", let us = cands.first(where: { $0.iso2 == "US" }) {
                return (us, national)
            }
            if code == "7", let ru = cands.first(where: { $0.iso2 == "RU" }) {
                return (ru, national)
            }
            return (cands[0], national)
        }
        return nil
    }
}
