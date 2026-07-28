import Foundation

/// Where each maker hides the HDMI-CEC switch.
///
/// Nobody calls it "HDMI-CEC" in their menus, and the setting is buried several
/// levels deep, so telling someone to "enable CEC" is not actionable. Each case
/// carries the brand's own name for it and the literal menu path.
enum TVBrand: String, CaseIterable, Identifiable {
    case samsung
    case lg
    case sony
    case tclOrRoku
    case hisense
    case vizio
    case philips
    case panasonic

    var id: Self { self }

    var name: String {
        switch self {
        case .samsung: "Samsung"
        case .lg: "LG"
        case .sony: "Sony"
        case .tclOrRoku: "TCL / Roku"
        case .hisense: "Hisense"
        case .vizio: "Vizio"
        case .philips: "Philips"
        case .panasonic: "Panasonic"
        }
    }

    /// What the maker calls HDMI-CEC.
    var featureName: String {
        switch self {
        case .samsung: "Anynet+"
        case .lg: "SimpLink"
        case .sony: "Bravia Sync"
        case .tclOrRoku: "Control other devices"
        case .hisense: "HDMI-CEC"
        case .vizio: "CEC"
        case .philips: "EasyLink"
        case .panasonic: "VIERA Link"
        }
    }

    /// The maker's own support page for the setting.
    var supportURL: URL? {
        switch self {
        case .samsung: URL(string: "https://www.samsung.com/us/support/answer/ANS10006946/")
        case .lg: URL(string: "https://www.lg.com/us/support/help-library/lg-tv-simplink-CT10000018")
        case .sony: URL(string: "https://www.sony.com/electronics/support/articles/00021747")
        case .tclOrRoku: URL(string: "https://support.roku.com/article/208755668")
        case .hisense: URL(string: "https://www.hisense-usa.com/support")
        case .vizio: URL(string: "https://support.vizio.com/s/article/Using-CEC")
        case .philips: URL(string: "https://www.philips.co.uk/c-f/XC000009262/what-is-easylink-hdmi-cec")
        case .panasonic: URL(string: "https://www.panasonic.com/global/support.html")
        }
    }

    var path: String {
        switch self {
        case .samsung:
            "Settings → All Settings → Connection → External Device Manager → Anynet+ (HDMI-CEC)"
        case .lg:
            "Settings → All Settings → General → Devices → HDMI Settings → SimpLink (HDMI-CEC)"
        case .sony:
            "Settings → Channels & Inputs → External inputs → Bravia Sync settings → Bravia Sync control"
        case .tclOrRoku:
            "Settings → System → Control other devices (CEC) → turn on 1-touch play"
        case .hisense:
            "Settings → System → HDMI & CEC → CEC Control"
        case .vizio:
            "Menu → System → CEC → set to Enable"
        case .philips:
            "Settings → All Settings → General Settings → EasyLink → HDMI-CEC"
        case .panasonic:
            "Menu → Setup → VIERA Link settings → VIERA Link → On"
        }
    }
}
