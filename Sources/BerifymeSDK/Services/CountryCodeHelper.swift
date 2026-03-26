import Foundation

/// Country code to country name mapping (aligned with React Native SDK countryCode.ts)
public struct CountryCodeHelper {
    private static let countryCodesToName: [String: String] = [
        "AF": "Afghanistan",
        "AL": "Albania",
        "DZ": "Algeria",
        "AS": "American Samoa",
        "AD": "Andorra",
        "AO": "Angola",
        "AI": "Anguilla",
        "AQ": "Antarctica",
        "AG": "Antigua and Barbuda",
        "AR": "Argentina",
        "AM": "Armenia",
        "AW": "Aruba",
        "AU": "Australia",
        "AT": "Austria",
        "AZ": "Azerbaijan",
        "BS": "Bahamas",
        "BH": "Bahrain",
        "BD": "Bangladesh",
        "BB": "Barbados",
        "BY": "Belarus",
        "BE": "Belgium",
        "BZ": "Belize",
        "BJ": "Benin",
        "BM": "Bermuda",
        "BT": "Bhutan",
        "BO": "Bolivia",
        "BA": "Bosnia and Herzegovina",
        "BW": "Botswana",
        "BR": "Brazil",
        "BN": "Brunei Darussalam",
        "BG": "Bulgaria",
        "BF": "Burkina Faso",
        "BI": "Burundi",
        "KH": "Cambodia",
        "CM": "Cameroon",
        "CA": "Canada",
        "CV": "Cape Verde",
        "KY": "Cayman Islands",
        "CF": "Central African Republic",
        "TD": "Chad",
        "CL": "Chile",
        "CN": "China",
        "CO": "Colombia",
        "KM": "Comoros",
        "CG": "Congo",
        "CD": "Congo, Democratic Republic of the",
        "CR": "Costa Rica",
        "CI": "Cote d'Ivoire",
        "HR": "Croatia",
        "CU": "Cuba",
        "CY": "Cyprus",
        "CZ": "Czech Republic",
        "DK": "Denmark",
        "DJ": "Djibouti",
        "DM": "Dominica",
        "DO": "Dominican Republic",
        "EC": "Ecuador",
        "EG": "Egypt",
        "SV": "El Salvador",
        "GQ": "Equatorial Guinea",
        "ER": "Eritrea",
        "EE": "Estonia",
        "ET": "Ethiopia",
        "FJ": "Fiji",
        "FI": "Finland",
        "FR": "France",
        "GA": "Gabon",
        "GM": "Gambia",
        "GE": "Georgia",
        "DE": "Germany",
        "GH": "Ghana",
        "GR": "Greece",
        "GL": "Greenland",
        "GD": "Grenada",
        "GU": "Guam",
        "GT": "Guatemala",
        "GN": "Guinea",
        "GW": "Guinea-Bissau",
        "GY": "Guyana",
        "HT": "Haiti",
        "HN": "Honduras",
        "HK": "Hong Kong",
        "HU": "Hungary",
        "IS": "Iceland",
        "IN": "India",
        "ID": "Indonesia",
        "IR": "Iran",
        "IQ": "Iraq",
        "IE": "Ireland",
        "IL": "Israel",
        "IT": "Italy",
        "JM": "Jamaica",
        "JP": "Japan",
        "JO": "Jordan",
        "KZ": "Kazakhstan",
        "KE": "Kenya",
        "KI": "Kiribati",
        "KP": "Korea (North)",
        "KR": "Korea (South)",
        "KW": "Kuwait",
        "KG": "Kyrgyzstan",
        "LA": "Lao PDR",
        "LV": "Latvia",
        "LB": "Lebanon",
        "LS": "Lesotho",
        "LR": "Liberia",
        "LY": "Libya",
        "LI": "Liechtenstein",
        "LT": "Lithuania",
        "LU": "Luxembourg",
        "MO": "Macao",
        "MK": "Macedonia",
        "MG": "Madagascar",
        "MW": "Malawi",
        "MY": "Malaysia",
        "MV": "Maldives",
        "ML": "Mali",
        "MT": "Malta",
        "MH": "Marshall Islands",
        "MR": "Mauritania",
        "MU": "Mauritius",
        "MX": "Mexico",
        "FM": "Micronesia",
        "MD": "Moldova",
        "MC": "Monaco",
        "MN": "Mongolia",
        "ME": "Montenegro",
        "MA": "Morocco",
        "MZ": "Mozambique",
        "MM": "Myanmar",
        "NA": "Namibia",
        "NR": "Nauru",
        "NP": "Nepal",
        "NL": "Netherlands",
        "NZ": "New Zealand",
        "NI": "Nicaragua",
        "NE": "Niger",
        "NG": "Nigeria",
        "NU": "Niue",
        "NF": "Norfolk Island",
        "MP": "Northern Mariana Islands",
        "NO": "Norway",
        "OM": "Oman",
        "PK": "Pakistan",
        "PW": "Palau",
        "PS": "Palestine",
        "PA": "Panama",
        "PG": "Papua New Guinea",
        "PY": "Paraguay",
        "PE": "Peru",
        "PH": "Philippines",
        "PL": "Poland",
        "PT": "Portugal",
        "PR": "Puerto Rico",
        "QA": "Qatar",
        "RO": "Romania",
        "RU": "Russian Federation",
        "RW": "Rwanda",
        "WS": "Samoa",
        "SM": "San Marino",
        "ST": "Sao Tome and Principe",
        "SA": "Saudi Arabia",
        "SN": "Senegal",
        "RS": "Serbia",
        "SC": "Seychelles",
        "SL": "Sierra Leone",
        "SG": "Singapore",
        "SK": "Slovakia",
        "SI": "Slovenia",
        "SB": "Solomon Islands",
        "SO": "Somalia",
        "ZA": "South Africa",
        "ES": "Spain",
        "LK": "Sri Lanka",
        "SD": "Sudan",
        "SR": "Suriname",
        "SZ": "Swaziland",
        "SE": "Sweden",
        "CH": "Switzerland",
        "SY": "Syrian Arab Republic",
        "TW": "Taiwan",
        "TJ": "Tajikistan",
        "TZ": "Tanzania",
        "TH": "Thailand",
        "TL": "Timor-Leste",
        "TG": "Togo",
        "TO": "Tonga",
        "TT": "Trinidad and Tobago",
        "TN": "Tunisia",
        "TR": "Turkey",
        "TM": "Turkmenistan",
        "TV": "Tuvalu",
        "UG": "Uganda",
        "UA": "Ukraine",
        "AE": "United Arab Emirates",
        "GB": "United Kingdom",
        "US": "United States",
        "UY": "Uruguay",
        "UZ": "Uzbekistan",
        "VU": "Vanuatu",
        "VE": "Venezuela",
        "VN": "Viet Nam",
        "YE": "Yemen",
        "ZM": "Zambia",
        "ZW": "Zimbabwe"
    ]
    
    /// Get country name by country code
    /// - Parameter code: Country code (e.g. "US", "TW")
    /// - Returns: Country name, or uppercased code if not found
    public static func getCountryNameByCode(_ code: String) -> String {
        return countryCodesToName[code.uppercased()] ?? code.uppercased()
    }
    
    /// Extract country code from phone number
    /// Note: Simplified implementation; may be inaccurate for complex formats
    /// Ideally use a dedicated library (e.g. libphonenumber)
    /// - Parameter phoneNumber: Phone number (may include +, e.g. "+886912345678" or "886912345678")
    /// - Returns: Country code (e.g. "TW"), or nil if cannot parse
    public static func getCountryCodeFromPhoneNumber(_ phoneNumber: String) -> String? {
        // Remove spaces and special chars, keep digits and +
        let cleaned = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Common country code mapping (international dialing codes)
        // Simplified; use dedicated library in production
        let countryCodeMap: [String: String] = [
            "1": "US",      // US/Canada
            "86": "CN",     // China
            "44": "GB",     // UK
            "81": "JP",     // Japan
            "82": "KR",     // Korea
            "886": "TW",    // Taiwan
            "852": "HK",    // Hong Kong
            "853": "MO",    // Macau
            "65": "SG",     // Singapore
            "60": "MY",     // Malaysia
            "62": "ID",     // Indonesia
            "66": "TH",     // Thailand
            "84": "VN",     // Vietnam
            "91": "IN",     // India
            "61": "AU",     // Australia
            "64": "NZ",     // New Zealand
            "33": "FR",     // France
            "49": "DE",     // Germany
            "39": "IT",     // Italy
            "34": "ES",     // Spain
            "31": "NL",     // Netherlands
            "32": "BE",     // Belgium
            "41": "CH",     // Switzerland
            "43": "AT",     // Austria
            "46": "SE",     // Sweden
            "47": "NO",     // Norway
            "45": "DK",     // Denmark
            "358": "FI",    // Finland
            "7": "RU",      // Russia
            "55": "BR",     // Brazil
            "52": "MX",     // Mexico
            "54": "AR",     // Argentina
            "27": "ZA",     // South Africa
            "20": "EG",     // Egypt
            "971": "AE",    // UAE
            "966": "SA",    // Saudi Arabia
            "974": "QA",    // Qatar
            "965": "KW",    // Kuwait
            "973": "BH",    // Bahrain
            "968": "OM",    // Oman
        ]
        
        // Check if starts with +
        let hasPlus = cleaned.hasPrefix("+")
        let digits = hasPlus ? String(cleaned.dropFirst()) : cleaned
        
        // Match longest country code first
        let sortedKeys = countryCodeMap.keys.sorted { $0.count > $1.count }
        
        for key in sortedKeys {
            if digits.hasPrefix(key) {
                return countryCodeMap[key]
            }
        }
        
        // Return nil if no match
        return nil
    }
}
