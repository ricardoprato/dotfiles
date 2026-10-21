import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "bin"))

import buds_protocol as bp  # noqa: E402


def frame(msg_id, payload=b""):
    return bp.encode(msg_id, payload)


class CrcTest(unittest.TestCase):
    def test_xmodem_check_value(self):
        self.assertEqual(bp.crc16(b"123456789"), 0x31C3)

    def test_empty(self):
        self.assertEqual(bp.crc16(b""), 0)


class EncodeTest(unittest.TestCase):
    def test_noise_control_vector(self):
        self.assertEqual(bp.encode(120, b"\x01"), bytes.fromhex("fd04007801d191dd"))

    def test_manager_info_vector(self):
        self.assertEqual(
            bp.encode(136, bytes([1, 1, 0x22])), bytes.fromhex("fd060088010122da58dd")
        )

    def test_rejects_oversize_payload(self):
        with self.assertRaises(ValueError):
            bp.encode(120, bytes(1021))

    def test_rejects_bad_id(self):
        with self.assertRaises(ValueError):
            bp.encode(256, b"")


class SplitTest(unittest.TestCase):
    def test_single_frame(self):
        frames, rest = bp.split_frames(frame(120, b"\x01"))
        self.assertEqual(frames, [(120, b"\x01")])
        self.assertEqual(rest, b"")

    def test_multiple_frames(self):
        buf = frame(96, b"\x01\x02") + frame(119, b"\x03") + frame(66, b"")
        frames, rest = bp.split_frames(buf)
        self.assertEqual(frames, [(96, b"\x01\x02"), (119, b"\x03"), (66, b"")])
        self.assertEqual(rest, b"")

    def test_partial_frame_kept_as_remainder(self):
        full = frame(97, b"\x05" * 10)
        frames, rest = bp.split_frames(full[:7])
        self.assertEqual(frames, [])
        self.assertEqual(rest, full[:7])
        frames, rest = bp.split_frames(rest + full[7:])
        self.assertEqual(frames, [(97, b"\x05" * 10)])
        self.assertEqual(rest, b"")

    def test_garbage_and_padding_resync(self):
        buf = b"\x00\x00\x13\x37" + frame(119, b"\x02") + b"\x00\x00\x00" + frame(66, b"\x78")
        frames, rest = bp.split_frames(buf)
        self.assertEqual(frames, [(119, b"\x02"), (66, b"\x78")])
        self.assertEqual(rest, b"")

    def test_bad_crc_rejected_then_next_frame_ok(self):
        bad = bytearray(frame(119, b"\x02"))
        bad[-2] ^= 0xFF
        frames, rest = bp.split_frames(bytes(bad) + frame(66, b""))
        self.assertEqual(frames, [(66, b"")])

    def test_bad_eom_rejected(self):
        bad = bytearray(frame(119, b"\x02"))
        bad[-1] = 0x00
        frames, _ = bp.split_frames(bytes(bad))
        self.assertEqual(frames, [])

    def test_false_start_inside_garbage(self):
        # 0xFD with an absurd size followed by a real frame must not lose the frame
        buf = b"\xfd\x03\x00" + frame(119, b"\x01")
        frames, rest = bp.split_frames(buf)
        self.assertEqual(frames, [(119, b"\x01")])

    def test_too_small_size_resyncs(self):
        buf = b"\xfd\x01\x00" + frame(66, b"")
        frames, _ = bp.split_frames(buf)
        self.assertEqual(frames, [(66, b"")])

    def test_remainder_is_bounded(self):
        frames, rest = bp.split_frames(b"\xfd\xff\x03" + b"\x01" * 5000)
        self.assertLessEqual(len(rest), bp.MAX_FRAME)


class CommandTest(unittest.TestCase):
    def cmd(self, line):
        return bp.build_command(line)

    def test_mode(self):
        self.assertEqual(self.cmd("mode off"), (120, b"\x00"))
        self.assertEqual(self.cmd("mode anc"), (120, b"\x01"))
        self.assertEqual(self.cmd("mode ambient"), (120, b"\x02"))
        self.assertEqual(self.cmd("mode adaptive"), (120, b"\x03"))

    def test_anc_level(self):
        self.assertEqual(self.cmd("anc_level low"), (131, b"\x00"))
        self.assertEqual(self.cmd("anc_level high"), (131, b"\x01"))

    def test_ambient_level(self):
        self.assertEqual(self.cmd("ambient_level 0"), (132, b"\x00"))
        self.assertEqual(self.cmd("ambient_level 2"), (132, b"\x02"))

    def test_conversation(self):
        self.assertEqual(self.cmd("conversation on"), (122, b"\x01"))
        self.assertEqual(self.cmd("conversation off"), (122, b"\x00"))

    def test_seamless_is_inverted(self):
        self.assertEqual(self.cmd("seamless on"), (175, b"\x00"))
        self.assertEqual(self.cmd("seamless off"), (175, b"\x01"))

    def test_touch_lock_layout(self):
        # [!lockAll, tap, double, triple, hold, doubleCall, holdCall]
        self.assertEqual(self.cmd("touch_lock on"), (144, bytes([0, 1, 1, 1, 1, 1, 1])))
        self.assertEqual(self.cmd("touch_lock off"), (144, bytes([1, 1, 1, 1, 1, 1, 1])))

    def test_find(self):
        self.assertEqual(self.cmd("find start"), (166, b""))
        self.assertEqual(self.cmd("find stop"), (161, b""))

    def test_manager_info(self):
        self.assertEqual(self.cmd("manager_info"), (136, bytes([1, 2, 0x22])))

    def test_extra_whitespace_and_case(self):
        self.assertEqual(self.cmd("  MODE   Anc \n"), (120, b"\x01"))

    def test_rejects_unknown(self):
        for line in ["", "bogus 1", "mode", "mode loud", "ambient_level 3",
                     "ambient_level -1", "ambient_level x", "seamless maybe",
                     "mode anc extra", "manager_info now", "find"]:
            with self.subTest(line=line):
                with self.assertRaises(ValueError):
                    self.cmd(line)


if __name__ == "__main__":
    unittest.main()
