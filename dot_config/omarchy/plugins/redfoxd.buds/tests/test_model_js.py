"""Runs Model.js (pure JS, shared with the QML widget) under node."""
import json
import os
import shutil
import subprocess
import unittest

HERE = os.path.dirname(__file__)
MODEL = os.path.join(HERE, "..", "Model.js")

HARNESS = """
const fs = require("fs"), vm = require("vm");
const ctx = vm.createContext({});
vm.runInContext(fs.readFileSync(process.argv[1], "utf8"), ctx);
const expr = process.argv[2];
console.log(JSON.stringify(vm.runInContext(expr, ctx)));
"""


@unittest.skipUnless(shutil.which("node"), "node not installed")
class ModelJsTest(unittest.TestCase):
    def js(self, expr):
        out = subprocess.run(["node", "-e", HARNESS, MODEL, expr],
                             capture_output=True, text=True, check=True).stdout
        return json.loads(out)

    def test_parse_full_line(self):
        line = json.dumps({
            "connected": True, "device": "Buds", "address": "AA:BB:CC:DD:EE:FF",
            "battery": {"left": 80, "right": 70, "case": 55},
            "placement": {"left": "wearing", "right": "case"},
            "charging": {"left": False, "right": True, "case": False},
            "noise_mode": "anc", "anc_level": "high", "ambient_level": 2,
            "detect_conversations": True, "seamless": False, "touch_locked": True})
        s = self.js("parseLine(%s)" % json.dumps(line))
        self.assertTrue(s["connected"])
        self.assertEqual(s["battery"], {"left": 80, "right": 70, "case": 55})
        self.assertEqual(s["mode"], "anc")
        self.assertEqual(s["ancLevel"], "high")
        self.assertEqual(s["ambientLevel"], 2)
        self.assertIs(s["seamless"], False)
        self.assertIs(s["touchLocked"], True)
        self.assertEqual(s["charging"]["right"], True)

    def test_garbage_lines(self):
        for line in ["", "not json", "[1,2]", "null", "42", '"x"']:
            self.assertIsNone(self.js("parseLine(%s)" % json.dumps(line)), line)

    def test_clamps_and_whitelists(self):
        line = json.dumps({
            "connected": True, "device": "x" * 200,
            "battery": {"left": 250, "right": -5, "case": "9"},
            "noise_mode": "<img src=x>", "anc_level": "ultra", "ambient_level": 9,
            "placement": {"left": "<b>hi</b>", "right": "case"},
            "error": "bad error!"})
        s = self.js("parseLine(%s)" % json.dumps(line))
        self.assertEqual(len(s["device"]), 64)
        self.assertEqual(s["battery"], {"left": 100, "right": 0, "case": None})
        self.assertEqual(s["mode"], "")
        self.assertEqual(s["ancLevel"], "")
        self.assertIsNone(s["ambientLevel"])
        self.assertEqual(s["placement"]["left"], "")
        self.assertEqual(s["placement"]["right"], "case")
        self.assertEqual(s["error"], "")

    def test_disconnected_line(self):
        s = self.js('parseLine(\'{"connected":false,"error":"device_not_found"}\')')
        self.assertFalse(s["connected"])
        self.assertEqual(s["error"], "device_not_found")

    def test_lowest_battery(self):
        self.assertEqual(self.js("lowestBattery({left: 80, right: 40, case: 10})"), 40)
        self.assertEqual(self.js("lowestBattery({left: 80, right: null, case: 10})"), 80)
        self.assertIsNone(self.js("lowestBattery({left: null, right: null, case: 10})"))

    def test_next_mode_cycle(self):
        self.assertEqual(self.js('nextMode("off")'), "anc")
        self.assertEqual(self.js('nextMode("anc")'), "ambient")
        self.assertEqual(self.js('nextMode("ambient")'), "off")
        self.assertEqual(self.js('nextMode("adaptive")'), "off")
        self.assertEqual(self.js('nextMode("")'), "anc")

    def test_hold_lifecycle(self):
        self.assertEqual(self.js('holdSet({}, "mode", "anc")'), {"mode": "anc"})
        # an actual value that matches releases the hold
        self.assertEqual(self.js('holdReconcile({mode: "anc"}, {mode: "anc"})'), {})
        # a different actual value keeps it
        self.assertEqual(self.js('holdReconcile({mode: "anc"}, {mode: "off"})'),
                         {"mode": "anc"})
        self.assertEqual(self.js('holdGet({mode: "anc"}, "mode", "off")'), "anc")
        self.assertEqual(self.js('holdGet({}, "mode", "off")'), "off")
        self.assertEqual(self.js('holdGet({seamless: false}, "seamless", true)'), False)

    def test_battery_text(self):
        self.assertEqual(self.js("batteryText(55)"), "55%")
        self.assertEqual(self.js("batteryText(null)"), "")


if __name__ == "__main__":
    unittest.main()
