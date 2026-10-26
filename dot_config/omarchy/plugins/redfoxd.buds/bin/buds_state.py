"""Pure helpers for the `buds` CLI: state merge, line buffering, JSON output."""

import json
import unicodedata

NAME_LIMIT = 64
LINE_LIMIT = 256
BACKOFF = (2, 5, 10, 30)


def clean_name(value):
    """Device names come from BlueZ and are untrusted: drop controls, bound length."""
    if not isinstance(value, str):
        return ""
    text = "".join(c for c in value if unicodedata.category(c)[0] != "C")
    return text[:NAME_LIMIT]


def fresh_state(address, name):
    return {"connected": True, "device": clean_name(name), "address": address}


def merge(state, fragment):
    """Fold a decoded fragment into state in place. Returns True if anything changed."""
    changed = False
    for key, value in fragment.items():
        if isinstance(value, dict):
            current = state.get(key)
            if not isinstance(current, dict):
                current = state[key] = {}
                changed = True
            changed |= merge(current, value)
        elif key not in state or state[key] != value:
            state[key] = value
            changed = True
    return changed


def pick_device(objects, address):
    """Choose the buds among BlueZ managed objects: (path, name, address, connected) or None.

    With an address, that device. Without one, connected buds first, then paired
    buds, so a disconnected pair can still be brought up with ConnectProfile.
    """
    candidates = []
    for path, ifaces in sorted(objects.items()):
        dev = ifaces.get("org.bluez.Device1")
        if not dev:
            continue
        name = dev.get("Name") or dev.get("Alias") or ""
        addr = dev.get("Address", "")
        connected = bool(dev.get("Connected"))
        if address:
            if addr.upper() == address.upper():
                return path, name, addr, connected
        elif "buds" in name.lower() and (connected or dev.get("Paired")):
            candidates.append((path, name, addr, connected))
    connected_first = sorted(candidates, key=lambda c: not c[3])
    return connected_first[0] if connected_first else None


def dumps(state):
    return json.dumps(state, separators=(",", ":"))


def backoff(attempt):
    return BACKOFF[min(attempt, len(BACKOFF) - 1)]


class LineBuffer:
    """Turn a byte stream into bounded text lines; overlong lines are dropped."""

    def __init__(self, limit=LINE_LIMIT):
        self.limit = limit
        self.buf = b""
        self.dropping = False

    def feed(self, chunk):
        lines = []
        self.buf += chunk
        while True:
            head, sep, tail = self.buf.partition(b"\n")
            if not sep:
                break
            self.buf = tail
            if self.dropping:
                self.dropping = False
            elif len(head) <= self.limit:
                text = head.decode("utf-8", errors="replace").strip()
                if text:
                    lines.append(text)
        if len(self.buf) > self.limit:
            self.buf = b""
            self.dropping = True
        return lines
