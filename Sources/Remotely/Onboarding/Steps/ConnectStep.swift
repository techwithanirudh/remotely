import RemotelyKit
import SwiftUI

struct ConnectStep: View {
    @Binding var brand: TVBrand

    var body: some View {
        StepLayout(
            title: "Connect over HDMI",
            hint: "Plug in the cable and switch the display to that input, then turn on "
                + "HDMI-CEC in its settings."
        ) {
            GestureHero(symbol: "cable.connector", tint: .cyan)
        } content: {
            BrandGuide(brand: $brand).card(radius: Theme.Control.radius)
        }
    }
}
