import importlib.machinery
import importlib.util
import os
import unittest
from unittest import mock

BIN = os.path.join(os.path.dirname(__file__), "..", "bin")
SCRIPT = os.path.join(BIN, "buds")
if not os.path.exists(SCRIPT):  # chezmoi source name
    SCRIPT = os.path.join(BIN, "executable_buds")

loader = importlib.machinery.SourceFileLoader("buds_script", SCRIPT)
spec = importlib.util.spec_from_loader("buds_script", loader)
buds = importlib.util.module_from_spec(spec)
loader.exec_module(buds)

PATH = "/org/bluez/hci0/dev_C4_77_64_28_71_16"


class FakeReply:
    def __init__(self, value):
        self.value = value

    def unpack(self):
        return self.value


class FakeBus:
    """Records BlueZ method calls; GetManagedObjects returns one Buds device."""

    def __init__(self, connected):
        self.connected = connected
        self.calls = []

    def register_object(self, *args):
        return 1

    def call_sync(self, name, path, iface, method, *args):
        self.calls.append(method)
        if method == "GetManagedObjects":
            dev = {"Name": "Buds3 Pro", "Address": "C4:77:64:28:71:16",
                   "Connected": self.connected, "Paired": True}
            return FakeReply(({PATH: {"org.bluez.Device1": dev}},))
        return None

    def call(self, name, path, iface, method, params, reply_type, flags, timeout,
             cancellable, callback, user_data):
        if method == "ConnectProfile":
            self.calls.append((method, params.unpack()[0]))
        else:
            self.calls.append(method)
        if callback:
            callback(self, None, user_data)

    def call_finish(self, result):
        return None


class CycleTest(unittest.TestCase):
    def cycle(self, connected):
        bus = FakeBus(connected)
        with mock.patch.object(buds.Gio, "bus_get_sync", return_value=bus):
            link = buds.Link("", lambda state: None)
            link._cycle()
        link._clear("timeout")
        return bus.calls

    def assert_audio_then_spp(self, calls):
        # Device1.Connect follows the last-used bearer (LE for these buds),
        # which never carries SPP. A2DP first brings up BR/EDR with an audio
        # profile on it; the buds drop a BR/EDR link that carries SPP alone
        # after about 30 s.
        self.assertNotIn("Connect", calls)
        profiles = [c[1] for c in calls if isinstance(c, tuple)]
        self.assertEqual(profiles, [buds.A2DP_SINK_UUID, buds.SPP_UUID])

    def test_disconnected_buds_connect_audio_then_spp(self):
        self.assert_audio_then_spp(self.cycle(connected=False))

    def test_connected_buds_connect_audio_then_spp(self):
        self.assert_audio_then_spp(self.cycle(connected=True))


if __name__ == "__main__":
    unittest.main()
