# Feature: Galaxy Buds shell plugin

## Objective
Omarchy bar widget `redfoxd.buds` to manage Samsung Galaxy Buds (target: Buds3 Pro,
`C4:77:64:28:71:16`) from the shell: battery, noise control mode, ANC level,
conversation detection, seamless connection (auto switch setting), touchpad lock,
find-my-earbuds.

## Why
GalaxyBudsClient works on Linux but is a separate GUI app. The user wants the
controls in the Omarchy bar, like the AirPods plugins in the catalog.

## Scope
- Galaxy Buds only (user decision 2026-10-21). Structure must not block adding
  AirPods later, but no AirPods code now (YAGNI).
- Plugin source: `dot_config/omarchy/plugins/redfoxd.buds/` (chezmoi), applied to
  `~/.config/omarchy/plugins/redfoxd.buds/`.
- Enable with `omarchy plugin enable redfoxd.buds --section right` (writes the
  unmanaged `~/.config/omarchy/shell.json`).

## Constraints
- Follow `$OMARCHY_PATH/default/agents/skills/omarchy/plugins.md`: plain-text
  `Text`, i18n catalogs (`en.json`, `es.json`), never edit packaged plugins.
- Backend: Python 3 stdlib + `gi.repository.Gio` (installed). No pip deps.
  Shebang `#!/usr/bin/python3`: mise's python comes first in PATH and lacks `gi`.
- Connect like GalaxyBudsClient on Linux: BlueZ `Profile1` client for SPP UUID
  `2e73a4ad-332d-41fc-90e2-16bef06523f2`, `Device1.ConnectProfile`, fd from
  `NewConnection`. Unregister stale profile first.
- Protocol (GalaxyBudsClient @754b6fd): frame `FD | hdr u16 LE (size=1+N+2) |
  msgId | payload | CRC16-XMODEM(msgId+payload) LE | DD`. Test vector:
  NOISE_CONTROLS(120)+`01` = `fd 04 00 78 01 d1 91 dd`.
- Widget pattern from `soup.airpods`: `bin/buds watch` prints one JSON status
  line per change, reads `key value` commands on stdin; QML `Process` +
  `SplitParser`, restart on exit, optimistic UI.
- Battery fallback from `Quickshell.Bluetooth` is not needed: protocol gives L/R/case.
- Auto switch: only the buds' "Seamless connection" setting (msg 175, inverted
  bool). Linux cannot take part in Samsung account Auto Switch.

## TDD
- Mode: strict, on. Source: user global CLAUDE.md ("Strict TDD Mode: enabled").
- Runner: `python3 -m unittest discover -s dot_config/omarchy/plugins/redfoxd.buds/tests -v`.
- QML has no test runner here; check with `omarchy plugin validate`.

## Tasks
- [x] T1 Protocol core (`bin/buds` pure functions: encode/decode/CRC, frame
      stream splitter, extended-status + status + noise/ack decoders, command
      builders) with unit tests incl. markup-free JSON and bounds. Route: delegated.
- [x] T2 Transport + `watch` loop (BlueZ Profile1 via Gio, reconnect, stdin
      commands, single-owner abstract socket for multi-monitor mirroring). Route: delegated.
- [x] T3 Widget (`manifest.json`, `Panel.qml`, `Model.js`, icon, `i18n/en.json`,
      `es.json`), validate. Route: delegated.
- [ ] T4 Apply via chezmoi, enable in bar, live check against the buds. Route: inline.

## Acceptance criteria
- `omarchy plugin validate` passes; widget appears in bar right section.
- With buds connected: battery L/R/case shown; changing noise mode from the
  popup changes it on the buds and the status updates back.
- Disconnected buds: widget shows disconnected state, no crash loop.

## Delivery
- Strategy: ask-on-risk. Forecast ~700 authored lines (over 400): ask chain
  strategy before PR. Work-unit commits on `feat/galaxy-buds-plugin`.

## Progress
- 2026-10-21: research done (protocol, plugin anatomy, catalog plugins). Branch created.
- 2026-10-21: T1 done, 44 unit tests green (strict TDD, RED observed on missing module). Commit `b1ef614` `feat(buds): add Galaxy Buds protocol core`; layout is `bin/buds_protocol.py` (pure) + `bin/executable_buds` (transport, T2).
- 2026-10-21: T2 done: `bin/executable_buds` (Gio Profile1 client, reconnect backoff, owner/mirror abstract socket `\0omarchy-buds`, `watch`/`status`) + `bin/buds_state.py` (pure, 12 tests). Owner/mirror roles checked with a fake link; BlueZ link checked live in T4. Commit `2029840` `feat(buds): add BlueZ transport and watch CLI`.
- 2026-10-21: T3 done: `manifest.json`, `Panel.qml`, `Model.js` (node-tested via `tests/test_model_js.py`), `i18n/{en,es}.json`, `README.md`; `omarchy plugin validate` passes. Commit `feat(buds): add bar widget and popup` (sha in git log). Removed accidentally committed `__pycache__`, added plugin `.gitignore`.
- Engram mirror `odd/galaxy-buds-plugin/tasks`: synced (project `dotfiles`, obs 572).
- 2026-10-21 T4 (partial): spot check 64 tests OK; `omarchy plugin enable redfoxd.buds --section right` done, shell reloaded it with no QML errors in journal. Live link blocked: GalaxyBudsClient holds the SPP UUID (`profile_busy`).
- 2026-10-21: user chose the plugin as default. GalaxyBudsClient stopped and its
  autostart disabled (`Hidden=true` in `~/.config/autostart/galaxybudsclient.desktop`,
  package kept). T1-T3 commits squashed into one (drops committed `__pycache__`).
  Live check pending: buds were not connected to the PC (`device_not_found`;
  `bluetoothctl connect` failed with `le-connection-abort-by-local`).

## Next step
T4: enable in bar, restart shell. Live check blocked until `galaxybudsclient` (pid holding the SPP UUID) is quit: `buds status` returned `profile_busy`.
