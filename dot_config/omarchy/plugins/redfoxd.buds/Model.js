// Pure helpers for the Buds widget: defensive parsing of the watcher's JSON
// lines, optimistic holds, and small formatting helpers. No QML types in here
// so the file can be tested under node.

var MODES = ["off", "anc", "ambient", "adaptive"]
var ANC_LEVELS = ["low", "high"]
var PLACEMENTS = ["disconnected", "wearing", "idle", "case", "closed_case", "charging"]
var NAME_LIMIT = 64

function emptyState() {
  return {
    connected: false,
    error: "",
    device: "",
    address: "",
    battery: { left: null, right: null, case: null },
    placement: { left: "", right: "" },
    charging: { left: false, right: false, case: false },
    mode: "",
    ancLevel: "",
    ambientLevel: null,
    detectConversations: null,
    seamless: null,
    touchLocked: null
  }
}

function clampBattery(value) {
  if (typeof value !== "number" || !isFinite(value)) return null
  return Math.max(0, Math.min(100, Math.round(value)))
}

function pick(list, value) {
  return typeof value === "string" && list.indexOf(value) >= 0 ? value : ""
}

function bool(value) {
  return typeof value === "boolean" ? value : null
}

function text(value) {
  if (typeof value !== "string") return ""
  return value.replace(/[\u0000-\u001f\u007f]/g, "").slice(0, NAME_LIMIT)
}

function errorCode(value) {
  return typeof value === "string" && /^[a-z_]{1,32}$/.test(value) ? value : ""
}

function object(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) ? value : {}
}

// One stdout line of `buds watch` -> normalized state, or null when it is not
// a JSON object. Unknown or malformed fields collapse to "unknown" values.
function parseLine(line) {
  var data
  try {
    data = JSON.parse(line)
  } catch (e) {
    return null
  }
  if (data === null || typeof data !== "object" || Array.isArray(data)) return null

  var state = emptyState()
  state.connected = data.connected === true
  state.error = errorCode(data.error)
  state.device = text(data.device)
  state.address = text(data.address)

  var battery = object(data.battery)
  state.battery = {
    left: clampBattery(battery.left),
    right: clampBattery(battery.right),
    case: clampBattery(battery.case)
  }
  var placement = object(data.placement)
  state.placement = { left: pick(PLACEMENTS, placement.left), right: pick(PLACEMENTS, placement.right) }
  var charging = object(data.charging)
  state.charging = { left: charging.left === true, right: charging.right === true, case: charging.case === true }

  state.mode = pick(MODES, data.noise_mode)
  state.ancLevel = pick(ANC_LEVELS, data.anc_level)
  var ambient = data.ambient_level
  state.ambientLevel = (ambient === 0 || ambient === 1 || ambient === 2) ? ambient : null
  state.detectConversations = bool(data.detect_conversations)
  state.seamless = bool(data.seamless)
  state.touchLocked = bool(data.touch_locked)
  return state
}

// Lowest of the two buds; the case does not count. null when neither is known.
function lowestBattery(battery) {
  var values = []
  if (battery && battery.left !== null && battery.left !== undefined) values.push(battery.left)
  if (battery && battery.right !== null && battery.right !== undefined) values.push(battery.right)
  return values.length ? Math.min.apply(null, values) : null
}

function batteryText(value) {
  return value === null || value === undefined ? "" : value + "%"
}

// Right-click cycle: off -> anc -> ambient -> off. Adaptive is experimental
// and not part of the cycle; leaving it goes to off.
function nextMode(mode) {
  if (mode === "off") return "anc"
  if (mode === "anc") return "ambient"
  if (mode === "ambient") return "off"
  if (mode === "adaptive") return "off"
  return "anc"
}

// Optimistic holds: a value the user just set stays on screen until the buds
// report the same value or the hold expires (the caller prunes on a timer).
function holdSet(pending, key, value) {
  var next = Object.assign({}, pending)
  next[key] = value
  return next
}

function holdGet(pending, key, actual) {
  return Object.prototype.hasOwnProperty.call(pending, key) ? pending[key] : actual
}

function holdReconcile(pending, state) {
  var next = {}
  for (var key in pending) {
    if (state[key] !== pending[key]) next[key] = pending[key]
  }
  return next
}
