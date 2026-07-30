import CoreGraphics
import Foundation
import RemoteKit

func cecLogTests() {
    Expect.suite("CEC log parsing") {
        let parser = CECLogParser()

        Expect.equal(
            parser
                .parse(
                    "19:00:00.000 corercd RX: TV -> Playback 1: <User Control Pressed> 02"
                ),
            .pressed(.down),
            "a pressed line decodes the wire code, not the English name"
        )
        Expect.equal(
            parser.parse("... <User Control Pressed> 00"), .pressed(.select), "0x00 is Select"
        )
        Expect.equal(
            parser.parse("... <User Control Pressed> 0D"), .pressed(.back), "0x0D is Back"
        )
        Expect.equal(
            parser.parse("... <User Control Released>"), .released,
            "a release carries no key code"
        )
        Expect.that(
            parser.parse("... <User Control Pressed> 41") == nil,
            "an unmapped code is ignored rather than guessed at"
        )
        Expect.that(parser.parse("unrelated daemon chatter") == nil, "unrelated lines are ignored")

        Expect.equal(
            parser
                .parse(
                    "CECBus <x> Link: Y; EDID: <CECEDIDAttributes: 0x600> Smart M70D vID: 0x4dd9"
                ),
            .attached("Smart M70D"),
            "the display name is read out of the EDID line"
        )
        Expect.that(
            parser
                .parse(
                    "CECBus <x> Link: N; EDID: <CECEDIDAttributes: 0x600> Smart M70D vID: 0x1"
                ) ==
                nil,
            "a down link is not reported as attached"
        )
    }
}
