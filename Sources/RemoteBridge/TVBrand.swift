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
