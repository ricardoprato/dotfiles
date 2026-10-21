"""Galaxy Buds SPP protocol: pure framing, decoding and command building.

No I/O in here. Layout notes (verified against the GalaxyBudsClient sources):

    frame = FD | header u16 LE (bits 0-9 = size = 1 + len(payload) + 2)
            | msg id | payload | CRC16-XMODEM(msg id + payload) u16 LE | DD
"""

SOM = 0xFD
EOM = 0xDD
SIZE_MASK = 0x3FF
MAX_FRAME = 1 + 2 + SIZE_MASK + 1
MAX_PAYLOAD = SIZE_MASK - 3

MSG_ACK = 66
MSG_STATUS = 96
MSG_EXTENDED_STATUS = 97
MSG_NOISE_UPDATE = 119
MSG_NOISE_CONTROLS = 120
MSG_DETECT_CONVERSATIONS = 122
MSG_ANC_LEVEL = 131
MSG_AMBIENT_LEVEL = 132
MSG_MANAGER_INFO = 136
MSG_LOCK_TOUCHPAD = 144
MSG_FIND_STOP = 161
MSG_FIND_START = 166
MSG_SEAMLESS = 175

NOISE_MODES = {0: "off", 1: "anc", 2: "ambient", 3: "adaptive"}
NOISE_MODE_IDS = {name: num for num, name in NOISE_MODES.items()}
PLACEMENTS = {0: "disconnected", 1: "wearing", 2: "idle", 3: "case", 4: "closed_case"}


def _build_crc_table():
    table = []
    for i in range(256):
        crc = i << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if crc & 0x8000 else (crc << 1)
        table.append(crc & 0xFFFF)
    return table


_CRC_TABLE = _build_crc_table()


def crc16(data):
    """CRC-16/XMODEM (poly 0x1021, init 0)."""
    crc = 0
    for byte in data:
        crc = ((crc << 8) & 0xFFFF) ^ _CRC_TABLE[((crc >> 8) ^ byte) & 0xFF]
    return crc


def encode(msg_id, payload=b""):
    if not isinstance(msg_id, int) or not 0 <= msg_id <= 255:
        raise ValueError("message id out of range")
    payload = bytes(payload)
    if len(payload) > MAX_PAYLOAD:
        raise ValueError("payload too large")
    size = 1 + len(payload) + 2
    body = bytes([msg_id]) + payload
    return (
        bytes([SOM]) + size.to_bytes(2, "little") + body
        + crc16(body).to_bytes(2, "little") + bytes([EOM])
    )


def split_frames(buf):
    """Extract complete valid frames from a byte buffer.

    Returns ([(msg_id, payload), ...], remainder). Garbage and zero padding
    between frames are skipped, bad frames resync on the next 0xFD, and the
    remainder never exceeds MAX_FRAME bytes.
    """
    buf = bytes(buf)
    frames = []
    pos = 0
    while True:
        start = buf.find(bytes([SOM]), pos)
        if start < 0:
            return frames, b""
        if len(buf) - start < 3:
            return frames, buf[start:]
        size = int.from_bytes(buf[start + 1:start + 3], "little") & SIZE_MASK
        if size < 3:
            pos = start + 1
            continue
        total = 1 + 2 + size + 1
        if len(buf) - start < total:
            return frames, buf[start:]
        body = buf[start + 3:start + 3 + size - 2]
        crc = int.from_bytes(buf[start + 3 + size - 2:start + 3 + size], "little")
        if buf[start + total - 1] != EOM or crc16(body) != crc:
            pos = start + 1
            continue
        frames.append((body[0], body[1:]))
        pos = start + total


# --- decoding -------------------------------------------------------------

def _battery(value):
    return value if 0 <= value <= 100 else None


def _placement(nibble):
    return PLACEMENTS.get(nibble)


def _charging_flags(byte):
    return {
        "left": bool(byte & (1 << 4)),
        "right": bool(byte & (1 << 2)),
        "case": bool(byte & 1),
    }


def _apply_placement_and_charging(state, p, placement_idx, charging_idx):
    if len(p) > placement_idx:
        state["placement"] = {
            "left": _placement((p[placement_idx] & 0xF0) >> 4),
            "right": _placement(p[placement_idx] & 0x0F),
        }
    if len(p) > charging_idx:
        charging = _charging_flags(p[charging_idx])
        state["charging"] = charging
        placement = state.setdefault("placement", {"left": None, "right": None})
        for side in ("left", "right"):
            if charging[side]:
                placement[side] = "charging"


def _battery_dict(p, left_idx, case_idx):
    battery = {"left": _battery(p[left_idx]), "right": _battery(p[left_idx + 1])}
    if len(p) > case_idx:
        battery["case"] = _battery(p[case_idx])
    return battery


def decode_extended_status(p):
    """Message 97, layout of Buds3 Pro (models >= Buds FE). Tolerates short payloads."""
    p = bytes(p)
    state = {}
    if len(p) > 3:
        state["battery"] = _battery_dict(p, 2, 7)
    _apply_placement_and_charging(state, p, 6, 42)
    if len(p) > 10:
        state["touch_locked"] = not (p[10] & 0x80)
    if len(p) > 12:
        state["noise_mode"] = NOISE_MODES.get(p[12])
    if len(p) > 19:
        state["seamless"] = p[19] == 0
    if len(p) > 23:
        state["ambient_level"] = p[23]
    if len(p) > 24:
        state["anc_level"] = "high" if p[24] == 1 else "low"
    if len(p) > 27:
        state["detect_conversations"] = p[26] == 1
        state["conversation_duration"] = p[27] if p[27] <= 2 else 1
    return state


def decode_status(p):
    """Message 96: partial status update (battery, placement, charging)."""
    p = bytes(p)
    state = {}
    if len(p) > 2:
        state["battery"] = _battery_dict(p, 1, 6)
    _apply_placement_and_charging(state, p, 5, 7)
    return state


def decode_noise_control(p):
    """Message 119: noise control mode changed on the buds."""
    p = bytes(p)
    mode = NOISE_MODES.get(p[0]) if p else None
    return {"noise_mode": mode} if mode else {}


_INVERTED_ACKS = {MSG_SEAMLESS}


def decode_ack(p):
    """Message 66: acknowledgement of one of our requests."""
    p = bytes(p)
    if not p:
        return {}
    value = p[1] if len(p) > 1 else None
    if value is not None and p[0] in _INVERTED_ACKS:
        value = 0 if value else 1
    return {"msg_id": p[0], "value": value}


def ack_to_state(ack):
    """Translate an ack into a state fragment for settings the buds do not re-announce."""
    msg_id, value = ack.get("msg_id"), ack.get("value")
    if value is None:
        return {}
    if msg_id == MSG_NOISE_CONTROLS:
        mode = NOISE_MODES.get(value)
        return {"noise_mode": mode} if mode else {}
    if msg_id == MSG_ANC_LEVEL and value in (0, 1):
        return {"anc_level": "high" if value else "low"}
    if msg_id == MSG_AMBIENT_LEVEL and 0 <= value <= 2:
        return {"ambient_level": value}
    if msg_id == MSG_DETECT_CONVERSATIONS:
        return {"detect_conversations": bool(value)}
    if msg_id == MSG_SEAMLESS:
        return {"seamless": bool(value)}
    return {}


def is_extended_status(msg_id):
    return msg_id == MSG_EXTENDED_STATUS


def decode_message(msg_id, payload):
    """Decode any known message into a state fragment (empty dict if unknown)."""
    if msg_id == MSG_EXTENDED_STATUS:
        return decode_extended_status(payload)
    if msg_id == MSG_STATUS:
        return decode_status(payload)
    if msg_id == MSG_NOISE_UPDATE:
        return decode_noise_control(payload)
    if msg_id == MSG_ACK:
        return ack_to_state(decode_ack(payload))
    return {}


# --- commands -------------------------------------------------------------

def _onoff(value):
    if value not in ("on", "off"):
        raise ValueError("expected on|off")
    return value == "on"


def _choice(table):
    def parse(value):
        if value not in table:
            raise ValueError("expected one of: " + ", ".join(table))
        return table[value]
    return parse


def _ambient(value):
    if value not in ("0", "1", "2"):
        raise ValueError("expected 0..2")
    return int(value)


def _touch_lock(value):
    # [!lockAll, tap, double, triple, hold, doubleCall, holdCall]; the gesture
    # flags are all kept enabled so the lock switch is the only thing that changes.
    return bytes([0 if _onoff(value) else 1] + [1] * 6)


_COMMANDS = {
    "mode": (MSG_NOISE_CONTROLS, lambda v: bytes([_choice(NOISE_MODE_IDS)(v)])),
    "anc_level": (MSG_ANC_LEVEL, lambda v: bytes([_choice({"low": 0, "high": 1})(v)])),
    "ambient_level": (MSG_AMBIENT_LEVEL, lambda v: bytes([_ambient(v)])),
    "conversation": (MSG_DETECT_CONVERSATIONS, lambda v: bytes([int(_onoff(v))])),
    "seamless": (MSG_SEAMLESS, lambda v: bytes([0 if _onoff(v) else 1])),
    "touch_lock": (MSG_LOCK_TOUCHPAD, _touch_lock),
}
_FIND = {"start": MSG_FIND_START, "stop": MSG_FIND_STOP}


def build_command(line):
    """Turn a `key value` line into (msg_id, payload). Raises ValueError if invalid."""
    parts = str(line).lower().split()
    if not parts:
        raise ValueError("empty command")
    key, args = parts[0], parts[1:]
    if key == "manager_info":
        if args:
            raise ValueError("manager_info takes no argument")
        return MSG_MANAGER_INFO, bytes([1, 2, 0x22])
    if len(args) != 1:
        raise ValueError("expected exactly one argument")
    if key == "find":
        if args[0] not in _FIND:
            raise ValueError("expected start|stop")
        return _FIND[args[0]], b""
    if key not in _COMMANDS:
        raise ValueError("unknown command")
    msg_id, build = _COMMANDS[key]
    return msg_id, build(args[0])
