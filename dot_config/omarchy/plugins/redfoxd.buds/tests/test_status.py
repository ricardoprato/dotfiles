import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "bin"))

import buds_protocol as bp  # noqa: E402


def ext_payload(**kw):
    """Build a Buds3 Pro extended status payload (43+ bytes)."""
    p = bytearray(48)
    p[0] = kw.get("rev", 3)
    p[2] = kw.get("l", 80)
    p[3] = kw.get("r", 70)
    p[4] = 1
    p[6] = (kw.get("pl", 1) << 4) | kw.get("pr", 3)
    p[7] = kw.get("case", 55)
    p[10] = kw.get("touch", 0x8F)  # bit7 set = not locked, gestures on
    p[12] = kw.get("mode", 1)
    p[19] = kw.get("seamless_byte", 0)
    p[23] = kw.get("amb", 2)
    p[24] = kw.get("anc", 1)
    p[26] = kw.get("conv", 1)
    p[27] = kw.get("dur", 1)
    p[42] = kw.get("charging", 0b00001)  # case bit0
    return bytes(p[: kw.get("length", 48)])


class ExtendedStatusTest(unittest.TestCase):
    def test_full_decode(self):
        s = bp.decode_extended_status(ext_payload())
        self.assertEqual(s["battery"], {"left": 80, "right": 70, "case": 55})
        self.assertEqual(s["placement"], {"left": "wearing", "right": "case"})
        self.assertEqual(s["noise_mode"], "anc")
        self.assertEqual(s["ambient_level"], 2)
        self.assertEqual(s["anc_level"], "high")
        self.assertTrue(s["detect_conversations"])
        self.assertEqual(s["conversation_duration"], 1)
        self.assertTrue(s["seamless"])
        self.assertFalse(s["touch_locked"])
        self.assertEqual(s["charging"], {"left": False, "right": False, "case": True})

    def test_noise_modes(self):
        for byte, name in [(0, "off"), (1, "anc"), (2, "ambient"), (3, "adaptive")]:
            s = bp.decode_extended_status(ext_payload(mode=byte))
            self.assertEqual(s["noise_mode"], name)

    def test_unknown_mode_is_none(self):
        s = bp.decode_extended_status(ext_payload(mode=9))
        self.assertIsNone(s["noise_mode"])

    def test_seamless_inversion_both_ways(self):
        self.assertTrue(bp.decode_extended_status(ext_payload(seamless_byte=0))["seamless"])
        self.assertFalse(bp.decode_extended_status(ext_payload(seamless_byte=1))["seamless"])

    def test_touch_locked_when_bit7_clear(self):
        self.assertTrue(bp.decode_extended_status(ext_payload(touch=0x0F))["touch_locked"])

    def test_duration_over_two_becomes_one(self):
        self.assertEqual(bp.decode_extended_status(ext_payload(dur=7))["conversation_duration"], 1)

    def test_short_payload_is_tolerant(self):
        s = bp.decode_extended_status(ext_payload(length=8))
        self.assertEqual(s["battery"], {"left": 80, "right": 70, "case": 55})
        self.assertNotIn("noise_mode", s)
        self.assertNotIn("seamless", s)

    def test_very_short_payload(self):
        self.assertEqual(bp.decode_extended_status(b"\x01\x02"), {})

    def test_no_charging_byte(self):
        s = bp.decode_extended_status(ext_payload(length=30))
        self.assertNotIn("charging", s)
        self.assertEqual(s["ambient_level"], 2)

    def test_battery_out_of_range_dropped(self):
        s = bp.decode_extended_status(ext_payload(l=200))
        self.assertIsNone(s["battery"]["left"])

    def test_charging_marks_placement(self):
        s = bp.decode_extended_status(ext_payload(pl=3, charging=0b10000))
        self.assertEqual(s["placement"]["left"], "charging")


class StatusTest(unittest.TestCase):
    def test_partial_update(self):
        s = bp.decode_status(bytes([3, 90, 60, 1, 0, (1 << 4) | 2, 40, 0b100]))
        self.assertEqual(s["battery"], {"left": 90, "right": 60, "case": 40})
        self.assertEqual(s["placement"], {"left": "wearing", "right": "charging"})
        self.assertEqual(s["charging"], {"left": False, "right": True, "case": False})

    def test_short(self):
        self.assertEqual(bp.decode_status(b"\x01"), {})
        s = bp.decode_status(bytes([3, 90, 60, 1, 0, 0x22]))
        self.assertEqual(s["battery"], {"left": 90, "right": 60})


class NoiseAckTest(unittest.TestCase):
    def test_noise_update(self):
        self.assertEqual(bp.decode_noise_control(b"\x02"), {"noise_mode": "ambient"})
        self.assertEqual(bp.decode_noise_control(b"\x03\x01"), {"noise_mode": "adaptive"})
        self.assertEqual(bp.decode_noise_control(b""), {})
        self.assertEqual(bp.decode_noise_control(b"\x09"), {})

    def test_ack_basic(self):
        self.assertEqual(bp.decode_ack(bytes([120, 1])), {"msg_id": 120, "value": 1})
        self.assertEqual(bp.decode_ack(bytes([144])), {"msg_id": 144, "value": None})
        self.assertEqual(bp.decode_ack(b""), {})

    def test_ack_seamless_inverted(self):
        self.assertEqual(bp.decode_ack(bytes([175, 0]))["value"], 1)
        self.assertEqual(bp.decode_ack(bytes([175, 1]))["value"], 0)

    def test_ack_to_state(self):
        a = lambda i, v: bp.ack_to_state({"msg_id": i, "value": v})  # noqa: E731
        self.assertEqual(a(120, 1), {"noise_mode": "anc"})
        self.assertEqual(a(131, 0), {"anc_level": "low"})
        self.assertEqual(a(132, 1), {"ambient_level": 1})
        self.assertEqual(a(122, 1), {"detect_conversations": True})
        self.assertEqual(a(175, 1), {"seamless": True})
        self.assertEqual(a(144, 1), {})
        self.assertEqual(a(120, None), {})


class DispatchTest(unittest.TestCase):
    def test_decode_message(self):
        self.assertEqual(bp.decode_message(119, b"\x01"), {"noise_mode": "anc"})
        self.assertIn("battery", bp.decode_message(97, ext_payload()))
        self.assertIn("battery", bp.decode_message(96, bytes([3, 90, 60, 1, 0, 0x12, 40])))
        self.assertEqual(bp.decode_message(66, bytes([120, 3])), {"noise_mode": "adaptive"})
        self.assertEqual(bp.decode_message(999, b""), {})

    def test_is_extended_status(self):
        self.assertTrue(bp.is_extended_status(97))
        self.assertFalse(bp.is_extended_status(96))


if __name__ == "__main__":
    unittest.main()
