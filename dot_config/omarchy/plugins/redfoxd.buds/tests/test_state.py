import json
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "bin"))

import buds_state as bs  # noqa: E402


class MergeTest(unittest.TestCase):
    def test_merge_nested_keeps_untouched_keys(self):
        state = {"battery": {"left": 50, "right": 60, "case": 70}}
        changed = bs.merge(state, {"battery": {"left": 40, "right": 60}})
        self.assertTrue(changed)
        self.assertEqual(state["battery"], {"left": 40, "right": 60, "case": 70})

    def test_merge_reports_no_change(self):
        state = {"noise_mode": "anc", "battery": {"left": 1}}
        self.assertFalse(bs.merge(state, {"noise_mode": "anc", "battery": {"left": 1}}))

    def test_merge_adds_new_keys(self):
        state = {}
        self.assertTrue(bs.merge(state, {"seamless": True}))
        self.assertEqual(state, {"seamless": True})

    def test_merge_none_overwrites(self):
        state = {"battery": {"case": 10}}
        bs.merge(state, {"battery": {"case": None}})
        self.assertIsNone(state["battery"]["case"])


class FreshStateTest(unittest.TestCase):
    def test_fresh_state(self):
        s = bs.fresh_state("AA:BB", "x" * 100)
        self.assertTrue(s["connected"])
        self.assertEqual(s["address"], "AA:BB")
        self.assertEqual(len(s["device"]), 64)


class CleanNameTest(unittest.TestCase):
    def test_strips_controls_and_truncates(self):
        self.assertEqual(bs.clean_name("Buds\n\x00<b>3"), "Buds<b>3")
        self.assertEqual(len(bs.clean_name("é" * 200)), 64)

    def test_non_string(self):
        self.assertEqual(bs.clean_name(None), "")


class DumpsTest(unittest.TestCase):
    def test_single_compact_line(self):
        line = bs.dumps({"connected": True, "device": "a\nb", "n": [1, 2]})
        self.assertNotIn("\n", line)
        self.assertNotIn(" ", line)
        self.assertEqual(json.loads(line)["device"], "a\nb")


class LineBufferTest(unittest.TestCase):
    def test_splits_lines_across_chunks(self):
        lb = bs.LineBuffer()
        self.assertEqual(lb.feed(b"mode anc\nconv"), ["mode anc"])
        self.assertEqual(lb.feed(b"ersation on\n\n"), ["conversation on"])

    def test_crlf_and_invalid_utf8(self):
        lb = bs.LineBuffer()
        self.assertEqual(lb.feed(b"mode off\r\n"), ["mode off"])
        self.assertEqual(lb.feed(b"\xff\xfe\n"), ["��"])

    def test_overlong_line_dropped(self):
        lb = bs.LineBuffer(limit=16)
        self.assertEqual(lb.feed(b"x" * 40), [])
        self.assertEqual(lb.feed(b"yyy\nmode off\n"), ["mode off"])


class BackoffTest(unittest.TestCase):
    def test_schedule(self):
        self.assertEqual([bs.backoff(i) for i in range(6)], [2, 5, 10, 30, 30, 30])


if __name__ == "__main__":
    unittest.main()
