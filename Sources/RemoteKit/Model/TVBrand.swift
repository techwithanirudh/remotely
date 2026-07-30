import Foundation

/// Where each maker hides the HDMI-CEC switch.
///
/// Nobody labels it "HDMI-CEC", and the setting sits several levels deep, so
/// telling someone to enable CEC is not actionable on its own.
public enum TVBrand: String, CaseIterable, Identifiable, Codable, Sendable {
    case samsung, lg, sony, tclRoku, hisense, vizio, philips, panasonic

    public var id: Self { self }

    public var name: String {
        switch self {
        case .samsung: "Samsung"
        case .lg: "LG"
        case .sony: "Sony"
        case .tclRoku: "TCL / Roku"
        case .hisense: "Hisense"
        case .vizio: "Vizio"
        case .philips: "Philips"
        case .panasonic: "Panasonic"
        }
    }

    /// The maker's own name for HDMI-CEC.
    public var featureName: String {
        switch self {
        case .samsung: "Anynet+"
        case .lg: "SimpLink"
        case .sony: "Bravia Sync"
        case .tclRoku: "Control other devices"
        case .hisense: "HDMI-CEC"
        case .vizio: "CEC"
        case .philips: "EasyLink"
        case .panasonic: "VIERA Link"
        }
    }

    public var menuPath: String {
        switch self {
        case .samsung:
            "Settings → All Settings → Connection → External Device Manager → Anynet+ (HDMI-CEC)"
        case .lg:
            "Settings → All Settings → General → Devices → HDMI Settings → SimpLink (HDMI-CEC)"
        case .sony:
            "Settings → Channels & Inputs → External inputs → Bravia Sync settings"
                + " → Bravia Sync control"
        case .tclRoku:
            "Settings → System → Control other devices (CEC) → 1-touch play"
        case .hisense:
            "Settings → System → HDMI & CEC → CEC Control"
        case .vizio:
            "Menu → System → CEC → Enable"
        case .philips:
            "Settings → All Settings → General Settings → EasyLink → HDMI-CEC"
        case .panasonic:
            "Menu → Setup → VIERA Link settings → VIERA Link → On"
        }
    }

    /// The maker's own page, where one has been confirmed to resolve.
    ///
    /// Support articles get moved and retired constantly, so the rest fall back
    /// to a search, which always lands somewhere current. Checking these for a
    /// 200 is not enough: a retired article redirects to the help-library index
    /// and answers 200 from there, which is how two dead links shipped. The URL
    /// has to come back unchanged, which is what `scripts/check-links.sh` does.
    var verifiedArticle: URL? {
        switch self {
        case .samsung:
            URL(string: "https://www.samsung.com/us/support/answer/ANS10006946/")
        case .lg:
            URL(
                string: "https://www.lg.com/us/support/help-library/lg-tv-how-to-enable-hdmi-cec--20153164607551"
            )
        case .tclRoku:
            URL(string: "https://support.roku.com/article/configure-hdmi-settings-on-your-tv")
        default:
            nil
        }
    }

    public var hasVerifiedArticle: Bool { verifiedArticle != nil }

    public var helpURL: URL? {
        if let verifiedArticle { return verifiedArticle }

        let query = "\(name) \(featureName) HDMI-CEC turn on"
        var components = URLComponents(string: "https://duckduckgo.com/")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}
